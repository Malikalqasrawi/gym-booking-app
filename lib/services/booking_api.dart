import '../models/availability.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/payment.dart';
import '../models/trainer.dart';
import '../models/training_category.dart';
import '../utils/dates.dart';
import 'api_client.dart';

/// Client for the branch, trainer and booking endpoints.
class BookingApi {
  BookingApi(this._client);

  final ApiClient _client;

  Future<List<Branch>> getBranches() async {
    final json = await _client.get('/api/branches');
    return (json['data'] as List)
        .map((item) => Branch.fromJson(item as Map<String, dynamic>))
        .toList();
  }

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
    final path = Uri(
      path: '/api/branches/$branchId/trainers',
      queryParameters: filters.isEmpty ? null : filters,
    ).toString();
    final json = await _client.get(path);
    return (json['data'] as List)
        .map((item) => Trainer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

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

  Future<List<Booking>> myBookings() async => _bookings(await _client.get('/api/bookings/mine'));

  /// The backend refunds the booking if it was already paid.
  Future<Booking> cancelBooking(int bookingId) async =>
      Booking.fromJson(await _client.post('/api/bookings/$bookingId/cancel', {}));

  Future<PaymentStart> startPayment(int bookingId) async =>
      PaymentStart.fromJson(await _client.post('/api/bookings/$bookingId/payment', {}));

  /// Has the backend check the payment with Stripe and mark the booking paid if it succeeded.
  Future<Booking> confirmPayment(int bookingId) async =>
      Booking.fromJson(await _client.post('/api/bookings/$bookingId/payment/confirm', {}));

  Future<List<Booking>> trainerRequests() async => _bookings(await _client.get('/api/trainer/requests'));

  /// Accepted (awaiting payment) and paid sessions that haven't ended yet.
  Future<List<Booking>> trainerSchedule() async => _bookings(await _client.get('/api/trainer/schedule'));

  Future<Booking> acceptRequest(int bookingId, {String? message}) async => Booking.fromJson(
      await _client.post('/api/trainer/requests/$bookingId/accept', _message(message)));

  Future<Booking> rejectRequest(int bookingId, {String? message}) async => Booking.fromJson(
      await _client.post('/api/trainer/requests/$bookingId/reject', _message(message)));

  /// ApiClient wraps JSON lists as {"data": [...]}.
  List<Booking> _bookings(Map<String, dynamic> json) => (json['data'] as List)
      .map((item) => Booking.fromJson(item as Map<String, dynamic>))
      .toList();

  Map<String, dynamic> _message(String? message) =>
      {if (message != null && message.trim().isNotEmpty) 'message': message.trim()};
}
