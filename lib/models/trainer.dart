import '../utils/dates.dart';
import 'training_category.dart';

class WorkingHours {
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  const WorkingHours({required this.dayOfWeek, required this.startTime, required this.endTime});

  factory WorkingHours.fromJson(Map<String, dynamic> json) {
    return WorkingHours(
      dayOfWeek: json['dayOfWeek'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
    );
  }

  Map<String, dynamic> toJson() => {'dayOfWeek': dayOfWeek, 'startTime': startTime, 'endTime': endTime};
}

class Trainer {
  final int id;
  final String fullName;
  final String specialty;
  final String bio;
  final int yearsOfExperience;
  final int? branchId;
  final String? branchName;
  final double? hourlyRate; // null when the trainer isn't bookable yet
  final TrainingCategory? category;
  final String? gender;
  final String? languages;
  final List<String> tags;
  final List<String> certifications;
  final List<WorkingHours> schedule;

  const Trainer({
    required this.id,
    required this.fullName,
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
  });

  bool get isFemale => gender == 'FEMALE';

  String get initials => fullName
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  /// Must match the backend's Trainer.priceFor().
  double? priceFor(int minutes) => hourlyRate == null ? null : hourlyRate! * minutes / 60;

  bool worksOn(DateTime date) {
    final day = backendDayName(date.weekday);
    return schedule.any((block) => block.dayOfWeek == day);
  }

  String get workingDaysLabel {
    final days = <String>[];
    for (final block in schedule) {
      final short = shortDayFromBackend(block.dayOfWeek);
      if (!days.contains(short)) days.add(short);
    }
    return days.isEmpty ? 'No schedule yet' : days.join(', ');
  }

  factory Trainer.fromJson(Map<String, dynamic> json) {
    return Trainer(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String,
      specialty: (json['specialty'] as String?) ?? '',
      bio: (json['bio'] as String?) ?? '',
      yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ?? 0,
      branchId: (json['branchId'] as num?)?.toInt(),
      branchName: json['branchName'] as String?,
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble(),
      category: TrainingCategory.fromCode(json['category'] as String?),
      gender: json['gender'] as String?,
      languages: json['languages'] as String?,
      tags: _strings(json['tags']),
      certifications: _strings(json['certifications']),
      schedule: ((json['schedule'] as List?) ?? const [])
          .map((item) => WorkingHours.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static List<String> _strings(Object? value) =>
      value is List ? value.map((item) => '$item').toList() : const <String>[];
}
