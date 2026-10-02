import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/booking.dart';
import 'package:gym_booking/models/review.dart';
import 'package:gym_booking/models/trainer.dart';
import 'package:gym_booking/screens/bookings/rate_session_sheet.dart';
import 'package:gym_booking/services/api_client.dart';
import 'package:gym_booking/services/booking_api.dart';
import 'package:gym_booking/widgets/star_rating.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';

Map<String, dynamic> reviewJson({String? reply, bool? hidden, String? hiddenReason}) => {
      'id': 7,
      'bookingId': 58,
      'trainerId': 2,
      'trainerName': 'Sara Haddad',
      'memberName': 'Malik Q.',
      'rating': 4,
      'comment': 'Very patient.',
      'sessionDate': '2026-10-05',
      'createdAt': '2026-10-06T18:30:00',
      if (reply != null) 'reply': reply,
      if (hidden != null) 'hidden': hidden,
      if (hiddenReason != null) 'hiddenReason': hiddenReason,
    };

Booking booking(int id, String date, {bool canReview = true, int? rating}) => Booking.fromJson({
      'id': id,
      'status': 'PAID',
      'trainerId': 2,
      'trainerName': 'Sara Haddad',
      'memberId': 9,
      'memberName': 'Malik',
      'branchId': 1,
      'branchName': 'Abdoun Branch',
      'date': date,
      'startTime': '10:00',
      'endTime': '11:00',
      'durationMinutes': 60,
      'price': 20.0,
      'canPay': false,
      'canCancel': false,
      'canReview': canReview,
      'rating': rating,
    });

void main() {
  test("a review with the trainer's answer, and the fields only the admin gets", () {
    final review = Review.fromJson(reviewJson(reply: 'Thanks, see you Monday!'));
    expect(review.rating, 4);
    expect(review.memberName, 'Malik Q.');
    expect(review.reply, 'Thanks, see you Monday!');
    expect(review.sessionDate, DateTime(2026, 10, 5));
    expect(review.hidden, isFalse, reason: 'members never get the field');

    final hidden = Review.fromJson(reviewJson(hidden: true, hiddenReason: 'Insulting language'));
    expect(hidden.hidden, isTrue);
    expect(hidden.hiddenReason, 'Insulting language');
    expect(hidden.reply, isNull);
  });

  test('a trainer has no average until their first review', () {
    final none = TrainerReviews.fromJson({'averageRating': null, 'reviewCount': 0, 'reviews': []});
    expect(none.averageRating, isNull);
    expect(none.reviews, isEmpty);

    final trainer = Trainer.fromJson({'id': 2, 'fullName': 'Sara Haddad', 'averageRating': 4.5, 'reviewCount': 2});
    expect(trainer.averageRating, 4.5);
    expect(trainer.reviewCount, 2);
    expect(Trainer.fromJson({'id': 3, 'fullName': 'Lina Nasser'}).reviewCount, 0);
  });

  test('the home screen asks about the latest session that can still be rated', () {
    final bookings = [
      booking(1, '2026-10-01'),
      booking(2, '2026-10-05'),
      booking(3, '2026-10-06', canReview: false, rating: 5), // already rated
    ];
    expect(Booking.nextToRate(bookings, {})?.id, 2);
    expect(Booking.nextToRate(bookings, {2})?.id, 1, reason: '"Not now" on session 2');
    expect(Booking.nextToRate(bookings, {1, 2}), isNull);
    expect(bookings[2].rating, 5);
  });

  testWidgets('the rating summary shows the average and the number of reviews', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            RatingSummary(average: 4.5, count: 2),
            RatingSummary(average: 5, count: 1, compact: true),
            RatingSummary(average: null, count: 0),
          ],
        ),
      ),
    ));
    expect(find.text('4.5'), findsOneWidget);
    expect(find.text(' · 2 reviews'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
    expect(find.text(' (1)'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(2), reason: 'nothing for a trainer without reviews');
  });

  testWidgets('rating a session needs a star, then sends the stars and the comment', (tester) async {
    final requests = <http.Request>[];
    final api = BookingApi(ApiClient(httpClient: MockClient((request) async {
      requests.add(request);
      return http.Response(jsonEncode(reviewJson()), 201, headers: {'content-type': 'application/json'});
    })));
    bool? sent;

    await tester.pumpWidget(Provider<BookingApi>.value(
      value: api,
      child: MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async => sent = await showRateSessionSheet(context, booking(58, '2026-10-05')),
              child: const Text('Rate'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Rate'));
    await tester.pumpAndSettle();
    expect(find.text('How was your session with Sara?'), findsOneWidget);

    await tester.tap(find.text('Send review'));
    await tester.pump();
    expect(find.text('Tap a star to rate the session.'), findsOneWidget);
    expect(requests, isEmpty);

    await tester.tap(find.byTooltip('4 stars'));
    await tester.pump();
    expect(find.text('Very good'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '  Very patient.  ');
    await tester.tap(find.text('Send review'));
    for (var i = 0; i < 10 && sent == null; i++) {
      await tester.pump();
    }
    await tester.pumpAndSettle();

    expect(requests.single.url.path, '/api/bookings/58/review');
    expect(jsonDecode(requests.single.body), {'rating': 4, 'comment': 'Very patient.'});
    expect(sent, isTrue);
    expect(find.text('Send review'), findsNothing, reason: 'the sheet closed');
  });
}
