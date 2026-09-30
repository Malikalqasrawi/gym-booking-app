import 'package:flutter/material.dart';

// TODO: show real photos once admins can upload them.

/// Initials avatar whose colour is derived from [id], so a trainer always gets the same one.
class TrainerAvatar extends StatelessWidget {
  const TrainerAvatar({super.key, required this.id, required this.name, this.radius = 28});

  final int id;
  final String name;
  final double radius;

  static const _colors = [
    Color(0xFF8E4B32),
    Color(0xFF3F6E8C),
    Color(0xFF5B7F3A),
    Color(0xFF7A4E8C),
    Color(0xFFB0662B),
    Color(0xFF2F7F77),
    Color(0xFF9C3D54),
    Color(0xFF4F5B93),
  ];

  String get _initials => name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: _colors[id % _colors.length],
      child: Text(
        _initials,
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: radius * 0.62),
      ),
    );
  }
}
