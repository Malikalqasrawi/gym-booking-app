import '../models/admin_booking.dart';
import '../models/admin_trainer.dart';
import '../models/blocked_time.dart';
import '../models/booking.dart';
import '../models/branch.dart';
import '../models/review.dart';
import '../models/trainer.dart';
import 'api_client.dart';

/// Client for the admin endpoints. The backend rejects these calls for non-admin tokens.
class AdminApi {
  AdminApi(this._client);

  final ApiClient _client;

  Future<List<AdminTrainer>> trainers() async {
    final json = await _client.get('/api/admin/trainers');
    return (json['data'] as List)
        .map((item) => AdminTrainer.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminTrainer> trainer(int id) async =>
      AdminTrainer.fromJson(await _client.get('/api/admin/trainers/$id'));

  /// Creates the trainer; the backend emails them an invite code.
  Future<AdminTrainer> createTrainer(TrainerDraft draft) async =>
      AdminTrainer.fromJson(await _client.post('/api/admin/trainers', draft.toJson()));

  Future<AdminTrainer> updateTrainer(int id, TrainerDraft draft) async =>
      AdminTrainer.fromJson(await _client.put('/api/admin/trainers/$id', draft.toJson()));

  /// Replaces the whole weekly schedule.
  Future<AdminTrainer> updateSchedule(int id, List<WorkingHours> blocks) async =>
      AdminTrainer.fromJson(await _client.put('/api/admin/trainers/$id/schedule', {
        'blocks': blocks.map((block) => block.toJson()).toList(),
      }));

  Future<AdminTrainer> resendInvite(int id) async =>
      AdminTrainer.fromJson(await _client.post('/api/admin/trainers/$id/invite', {}));

  /// Cancels the trainer's upcoming bookings; paid ones are refunded in full.
  Future<TrainerDeactivation> deactivate(int id, {String? reason}) async =>
      TrainerDeactivation.fromJson(await _client.post('/api/admin/trainers/$id/deactivate', {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }));

  Future<AdminTrainer> reactivate(int id) async =>
      AdminTrainer.fromJson(await _client.post('/api/admin/trainers/$id/reactivate', {}));

  /// Upcoming sessions (soonest first), or past ones (latest first) when [past] is true.
  Future<List<AdminBooking>> bookings({bool past = false, int? branchId, int? trainerId, BookingStatus? status}) async {
    final filters = <String, String>{
      if (past) 'past': 'true',
      if (branchId != null) 'branchId': '$branchId',
      if (trainerId != null) 'trainerId': '$trainerId',
      if (status != null) 'status': status.name.toUpperCase(),
    };
    final path = Uri(path: '/api/admin/bookings', queryParameters: filters.isEmpty ? null : filters).toString();
    final json = await _client.get(path);
    return (json['data'] as List)
        .map((item) => AdminBooking.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<AdminBooking> booking(int id) async => AdminBooking.fromJson(await _client.get('/api/admin/bookings/$id'));

  /// Newest first. [hidden] true or false filters; null means all.
  Future<List<Review>> reviews({bool? hidden}) async {
    final path = Uri(path: '/api/admin/reviews', queryParameters: hidden == null ? null : {'hidden': '$hidden'}).toString();
    final json = await _client.get(path);
    return (json['data'] as List).map((item) => Review.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Hides the review from the trainer's profile; the member is emailed the reason.
  Future<Review> hideReview(int id, String reason) async =>
      Review.fromJson(await _client.post('/api/admin/reviews/$id/hide', {'reason': reason.trim()}));

  Future<Review> showReview(int id) async => Review.fromJson(await _client.post('/api/admin/reviews/$id/show', {}));

  /// Cancels on the gym's side; a paid session is refunded in full.
  Future<AdminBooking> cancelBooking(int id, {String? reason}) async =>
      AdminBooking.fromJson(await _client.post('/api/admin/bookings/$id/cancel', {
        if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
      }));

  Future<List<BlockedTime>> blockedTimes() async {
    final json = await _client.get('/api/admin/blocked-times');
    return (json['data'] as List)
        .map((item) => BlockedTime.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// How many bookings the block would cancel. Nothing is saved.
  Future<BlockImpact> previewBlock(BlockedTimeDraft draft) async =>
      BlockImpact.fromJson(await _client.post('/api/admin/blocked-times/preview', draft.toJson()));

  /// Saves the block and cancels the bookings inside it, refunding paid ones in full.
  Future<BlockedTimeCreated> createBlock(BlockedTimeDraft draft) async =>
      BlockedTimeCreated.fromJson(await _client.post('/api/admin/blocked-times', draft.toJson()));

  Future<void> deleteBlock(int id) => _client.delete('/api/admin/blocked-times/$id');

  Future<Branch> createBranch(BranchDraft draft) async =>
      Branch.fromJson(await _client.post('/api/branches', draft.toJson()));

  Future<Branch> updateBranch(int id, BranchDraft draft) async =>
      Branch.fromJson(await _client.put('/api/branches/$id', draft.toJson()));

  /// Refused (BRANCH_IN_USE) while the branch has trainers or bookings.
  Future<void> deleteBranch(int id) => _client.delete('/api/branches/$id');
}
