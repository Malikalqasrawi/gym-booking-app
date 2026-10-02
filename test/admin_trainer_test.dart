import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/models/admin_trainer.dart';
import 'package:gym_booking/models/trainer.dart';
import 'package:gym_booking/models/training_category.dart';

void main() {
  test('reads the admin trainer JSON', () {
    final trainer = AdminTrainer.fromJson({
      'id': 31,
      'fullName': 'Rami Khalil',
      'email': 'rami@test.com',
      'phone': '0791234567',
      'status': 'INVITED',
      'inviteExpiresAt': '2026-10-08T10:15',
      'specialty': 'Boxing',
      'bio': null,
      'yearsOfExperience': 8,
      'branchId': 2,
      'branchName': 'Khalda Branch',
      'hourlyRate': 25,
      'category': 'BOXING',
      'gender': 'MALE',
      'languages': 'Arabic',
      'tags': ['Boxing'],
      'certifications': [],
      'schedule': [
        {'dayOfWeek': 'SUNDAY', 'startTime': '16:00', 'endTime': '20:00'},
      ],
      'upcomingBookings': 3,
    });
    expect(trainer.status, TrainerStatus.invited);
    expect(trainer.inviteExpiresAt, DateTime(2026, 10, 8, 10, 15));
    expect(trainer.bio, '');
    expect(trainer.hourlyRate, 25.0);
    expect(trainer.category, TrainingCategory.boxing);
    expect(trainer.schedule.single.startTime, '16:00');
    expect(trainer.upcomingBookings, 3);
  });

  test('draft JSON matches the backend request', () {
    final draft = TrainerDraft(
      fullName: 'Rami Khalil',
      email: 'rami@test.com',
      phone: '0791234567',
      branchId: 2,
      category: TrainingCategory.boxing,
      gender: 'MALE',
      hourlyRate: 22.5,
      specialty: 'Boxing',
      bio: '',
      yearsOfExperience: 8,
      languages: 'Arabic, English',
      tags: TrainerDraft.splitTags(' Boxing, , Kids '),
      certifications: TrainerDraft.splitLines('Coach Level 1\n\n  First aid '),
    );
    final json = draft.toJson();
    expect(json['category'], 'BOXING');
    expect(json['hourlyRate'], 22.5);
    expect(json['tags'], ['Boxing', 'Kids']);
    expect(json['certifications'], ['Coach Level 1', 'First aid']);
  });

  group('scheduleProblem', () {
    WorkingHours block(String day, String start, String end) =>
        WorkingHours(dayOfWeek: day, startTime: start, endTime: end);

    test('accepts split shifts on the same day', () {
      expect(scheduleProblem([block('MONDAY', '08:00', '12:00'), block('MONDAY', '16:00', '20:00')]), isNull);
    });

    test('rejects overlapping blocks', () {
      expect(
        scheduleProblem([block('MONDAY', '11:00', '14:00'), block('MONDAY', '08:00', '12:00')]),
        'Monday: 08:00-12:00 overlaps 11:00-14:00.',
      );
    });

    test('rejects a block that ends before it starts', () {
      expect(scheduleProblem([block('SUNDAY', '14:00', '09:00')]), 'Sunday: 14:00-09:00 ends before it starts.');
    });
  });
}
