import 'booking.dart';

/// A booking as the admin sees it: the member's view plus contact details.
class AdminBooking {
  final Booking booking;
  final String memberEmail;
  final String memberPhone;
  final String trainerEmail;
  final bool gymCanCancel; // until the session starts, even within the members' last 24 h

  const AdminBooking({
    required this.booking,
    required this.memberEmail,
    required this.memberPhone,
    required this.trainerEmail,
    required this.gymCanCancel,
  });

  int get id => booking.id;

  /// The backend sends the booking fields and the extra ones in a single object.
  factory AdminBooking.fromJson(Map<String, dynamic> json) => AdminBooking(
        booking: Booking.fromJson(json),
        memberEmail: (json['memberEmail'] as String?) ?? '',
        memberPhone: (json['memberPhone'] as String?) ?? '',
        trainerEmail: (json['trainerEmail'] as String?) ?? '',
        gymCanCancel: json['gymCanCancel'] as bool? ?? false,
      );
}
