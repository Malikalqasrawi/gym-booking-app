import '../models/admin_trainer.dart';
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
}
