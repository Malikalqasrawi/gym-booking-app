import 'package:flutter/material.dart';

/// A round avatar with the person's initials, e.g. "SH" for Sara Haddad.
/// Each id always gets the same colour, so the list looks varied but stays consistent.
/// (Real photos can come later, when the admin can upload them.)
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
