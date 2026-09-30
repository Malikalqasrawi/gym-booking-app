import 'package:flutter/material.dart';

/// Matches the Java enum `TrainingCategory`. Each value has the code the backend uses,
/// the words the app shows, and an icon.
enum TrainingCategory {
  strength('STRENGTH', 'Strength', Icons.fitness_center),
  hiit('HIIT', 'HIIT & cardio', Icons.local_fire_department),
  yoga('YOGA', 'Yoga', Icons.self_improvement),
  pilates('PILATES', 'Pilates', Icons.accessibility_new),
  boxing('BOXING', 'Boxing', Icons.sports_mma),
  crossfit('CROSSFIT', 'CrossFit', Icons.sports_gymnastics),
  rehab('REHAB', 'Rehab & mobility', Icons.healing);

  const TrainingCategory(this.code, this.label, this.icon);

  final String code; // "YOGA": sent to / received from the backend
  final String label; // "Yoga": shown in the app
  final IconData icon;

  /// "YOGA" → TrainingCategory.yoga (null if missing or unknown)
  static TrainingCategory? fromCode(String? code) =>
      TrainingCategory.values.where((category) => category.code == code).firstOrNull;
}
