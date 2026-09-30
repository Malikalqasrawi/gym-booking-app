import 'package:flutter/material.dart';

/// Mirrors the backend's TrainingCategory enum; [code] is the API value.
enum TrainingCategory {
  strength('STRENGTH', 'Strength', Icons.fitness_center),
  hiit('HIIT', 'HIIT & cardio', Icons.local_fire_department),
  yoga('YOGA', 'Yoga', Icons.self_improvement),
  pilates('PILATES', 'Pilates', Icons.accessibility_new),
  boxing('BOXING', 'Boxing', Icons.sports_mma),
  crossfit('CROSSFIT', 'CrossFit', Icons.sports_gymnastics),
  rehab('REHAB', 'Rehab & mobility', Icons.healing);

  const TrainingCategory(this.code, this.label, this.icon);

  final String code;
  final String label;
  final IconData icon;

  /// Returns null for a missing or unknown code.
  static TrainingCategory? fromCode(String? code) =>
      TrainingCategory.values.where((category) => category.code == code).firstOrNull;
}
