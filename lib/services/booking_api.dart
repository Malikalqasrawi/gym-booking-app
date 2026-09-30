import '../models/availability.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/payment.dart';
import '../models/trainer.dart';
import '../models/training_category.dart';
import '../utils/dates.dart';
import 'api_client.dart';

/// Dart functions for the Java booking endpoints.
/// (All of them need the login token; ApiClient adds it automatically.)
class BookingApi {
  BookingApi(this._client);

  final ApiClient _client;

  /// GET /api/branches → a JSON list. ApiClient wraps lists as {"data": [...]}.
  Future<List<Branch>> getBranches() async {
    final json = await _client.get('/api/branches');
    return (json['data'] as List)
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/branches/{id}/trainers?category=YOGA&gender=FEMALE&maxRate=20  (every filter is optional)
  Future<List<Trainer>> getTrainersForBranch(
    int branchId, {
    TrainingCategory? category,
    String? gender,
    int? maxRate,
  }) async {
    final filters = <String, String>{
      if (category != null) 'category': category.code,
      if (gender != null) 'gender': gender,
      if (maxRate != null) 'maxRate': '$maxRate',
    };
    // Uri builds the "?a=1&b=2" part for us (and escapes special characters)
    final path = Uri(
      path: '/api/branches/$branchId/trainers',
      queryParameters: filters.isEmpty ? null : filters,
    ).toString();
    final json = await _client.get(path);
    return (json['data'] as List)
        .map((item) => Trainer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/trainers/{id}/availability?date=2026-10-04&duration=60
  Future<Availability> getAvailability({
    required int trainerId,
    required DateTime date,
    required int durationMinutes,
  }) async {
    final json = await _client.get(
      '/api/trainers/$trainerId/availability?date=${isoDate(date)}&duration=$durationMinutes',
    );
    return Availability.fromJson(json);
  }

  // ------------------------------------------------------------------
  // Member
  // ------------------------------------------------------------------

  /// POST /api/bookings  → the new booking (status "Waiting for trainer")
  Future<Booking> requestSession({
    required int trainerId,
    required DateTime date,
    required String startTime,
    required int durationMinutes,
    String? note,
  }) async {
    final json = await _client.post('/api/bookings', {
      'trainerId': trainerId,
      'date': isoDate(date),
      'startTime': startTime,
      'durationMinutes': durationMinutes,
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    });
    return Booking.fromJson(json);
  }

  /// GET /api/bookings/mine
  Future<List<Booking>> myBookings() async => _bookings(await _client.get('/api/bookings/mine'));

  /// POST /api/bookings/{id}/cancel  (a paid booking is refunded by the backend)
  Future<Booking> cancelBooking(int bookingId) async =>
      Booking.fromJson(await _client.post('/api/bookings/$bookingId/cancel', {}));

  /// POST /api/bookings/{id}/payment  → what's needed to open Stripe's payment screen
  Future<PaymentStart> startPayment(int bookingId) async =>
      PaymentStart.fromJson(await _client.post('/api/bookings/$bookingId/payment', {}));

  /// POST /api/bookings/{id}/payment/confirm  → the backend asks Stripe; if paid, the booking is PAID
  Future<Booking> confirmPayment(int bookingId) async =>
      Booking.fromJson(await _client.post('/api/bookings/$bookingId/payment/confirm', {}));

  // ------------------------------------------------------------------
  // Trainer
  // ------------------------------------------------------------------

  /// GET /api/trainer/requests  → requests waiting for my answer
  Future<List<Booking>> trainerRequests() async => _bookings(await _client.get('/api/trainer/requests'));

  /// GET /api/trainer/schedule  → my accepted (awaiting payment) and paid sessions that haven't finished
  Future<List<Booking>> trainerSchedule() async => _bookings(await _client.get('/api/trainer/schedule'));

  /// POST /api/trainer/requests/{id}/accept   { "message": "..." } (optional)
  Future<Booking> acceptRequest(int bookingId, {String? message}) async => Booking.fromJson(
      await _client.post('/api/trainer/requests/$bookingId/accept', _message(message)));

  /// POST /api/trainer/requests/{id}/reject   { "message": "..." } (optional)
  Future<Booking> rejectRequest(int bookingId, {String? message}) async => Booking.fromJson(
      await _client.post('/api/trainer/requests/$bookingId/reject', _message(message)));

  // ------------------------------------------------------------------

  /// ApiClient wraps JSON lists as {"data": [...]}.
  List<Booking> _bookings(Map<String, dynamic> json) => (json['data'] as List)
      .map((item) => Booking.fromJson(item as Map<String, dynamic>))
      .toList();

  Map<String, dynamic> _message(String? message) =>
      {if (message != null && message.trim().isNotEmpty) 'message': message.trim()};
}
