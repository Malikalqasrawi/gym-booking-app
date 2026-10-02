import 'trainer.dart';
import 'training_category.dart';

enum TrainerStatus {
  invited('Invite sent'),
  active('Active'),
  deactivated('Deactivated');

  const TrainerStatus(this.label);

  final String label;

  static TrainerStatus fromJson(String value) => TrainerStatus.values.firstWhere(
        (status) => status.name.toUpperCase() == value.toUpperCase(),
        orElse: () => TrainerStatus.active,
      );
}

/// A trainer as the admin sees them: the public profile plus contact details and account status.
class AdminTrainer {
  final int id;
  final String fullName;
  final String email;
  final String phone;
  final TrainerStatus status;
  final DateTime? inviteExpiresAt; // only while the invite is pending
  final String specialty;
  final String bio;
  final int yearsOfExperience;
  final int? branchId;
  final String? branchName;
  final double? hourlyRate;
  final TrainingCategory? category;
  final String? gender;
  final String languages;
  final List<String> tags;
  final List<String> certifications;
  final List<WorkingHours> schedule;
  final int upcomingBookings;

  const AdminTrainer({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.status,
    required this.inviteExpiresAt,
    required this.specialty,
    required this.bio,
    required this.yearsOfExperience,
    required this.branchId,
    required this.branchName,
    required this.hourlyRate,
    required this.category,
    required this.gender,
    required this.languages,
    required this.tags,
    required this.certifications,
    required this.schedule,
    required this.upcomingBookings,
  });

  factory AdminTrainer.fromJson(Map<String, dynamic> json) {
    final invite = json['inviteExpiresAt'] as String?;
    return AdminTrainer(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      email: json['email'] as String,
      phone: (json['phone'] as String?) ?? '',
      status: TrainerStatus.fromJson(json['status'] as String),
      inviteExpiresAt: invite == null ? null : DateTime.parse(invite),
      specialty: (json['specialty'] as String?) ?? '',
      bio: (json['bio'] as String?) ?? '',
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ?? 0,
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      category: TrainingCategory.fromCode(json['category'] as String?),
      gender: json['gender'] as String?,
      languages: (json['languages'] as String?) ?? '',
      tags: _strings(json['tags']),
      certifications: _strings(json['certifications']),
      schedule: ((json['schedule'] as List?) ?? const [])
          .map((item) => WorkingHours.fromJson(item as Map<String, dynamic>))
          .toList(),
      upcomingBookings: (json['upcomingBookings'] as num?)?.toInt() ?? 0,
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.map((item) => '$item').toList() : const <String>[];
}

/// Result of deactivating a trainer.
class TrainerDeactivation {
  final AdminTrainer trainer;
  final int cancelledBookings;
  final int refundedBookings;

  const TrainerDeactivation({
    required this.trainer,
    required this.cancelledBookings,
    required this.refundedBookings,
  });

  factory TrainerDeactivation.fromJson(Map<String, dynamic> json) => TrainerDeactivation(
        trainer: AdminTrainer.fromJson(json['trainer'] as Map<String, dynamic>),
        cancelledBookings: (json['cancelledBookings'] as num).toInt(),
        refundedBookings: (json['refundedBookings'] as num).toInt(),
      );
}

/// Trainer details entered by the admin. [toJson] matches the backend's TrainerRequest.
class TrainerDraft {
  final String fullName;
  final String email;
  final String phone;
  final int branchId;
  final TrainingCategory category;
  final String gender;
  final double hourlyRate;
  final String specialty;
  final String bio;
  final int yearsOfExperience;
  final String languages;
  final List<String> tags;
  final List<String> certifications;

  const TrainerDraft({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.branchId,
    required this.category,
    required this.gender,
    required this.hourlyRate,
    required this.specialty,
    required this.bio,
    required this.yearsOfExperience,
    required this.languages,
    required this.tags,
    required this.certifications,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'branchId': branchId,
        'category': category.code,
        'gender': gender,
        'hourlyRate': hourlyRate,
        'specialty': specialty,
        'bio': bio,
        'yearsOfExperience': yearsOfExperience,
        'languages': languages,
        'tags': tags,
        'certifications': certifications,
      };

  /// "Strength, Beginners" -> ["Strength", "Beginners"].
  static List<String> splitTags(String text) =>
      text.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();

  /// One certification per line.
  static List<String> splitLines(String text) =>
      text.split('\n').map((line) => line.trim()).where((line) => line.isNotEmpty).toList();
}

/// Returns why the weekly schedule is invalid, or null if it's fine. Mirrors the backend check:
/// every block ends after it starts and blocks on the same day don't overlap.
String? scheduleProblem(List<WorkingHours> blocks) {
  final byDay = <String, List<WorkingHours>>{};
  for (final block in blocks) {
    byDay.putIfAbsent(block.dayOfWeek, () => []).add(block);
  }
  for (final entry in byDay.entries) {
    final day = entry.key[0] + entry.key.substring(1).toLowerCase();
    // "HH:mm" strings sort in time order.
    final sorted = [...entry.value]..sort((a, b) => a.startTime.compareTo(b.startTime));
    for (var i = 0; i < sorted.length; i++) {
      final block = sorted[i];
      if (block.endTime.compareTo(block.startTime) <= 0) {
        return '$day: ${block.startTime}-${block.endTime} ends before it starts.';
      }
      if (i > 0 && block.startTime.compareTo(sorted[i - 1].endTime) < 0) {
        final previous = sorted[i - 1];
        return '$day: ${previous.startTime}-${previous.endTime} overlaps ${block.startTime}-${block.endTime}.';
      }
    }
  }
  return null;
}
