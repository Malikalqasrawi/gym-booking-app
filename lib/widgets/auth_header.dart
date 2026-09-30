import 'package:flutter/material.dart';

/// Icon + big title + subtitle at the top of the auth screens.
class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 32, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(height: 20),
        Text(title, style: text.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(subtitle, style: text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    );
  }
}
