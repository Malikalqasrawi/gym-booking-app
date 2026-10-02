import 'package:flutter/material.dart';

import '../models/admin_trainer.dart';

class TrainerStatusChip extends StatelessWidget {
  const TrainerStatusChip({super.key, required this.status});

  final TrainerStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color bg, Color fg) = switch (status) {
      TrainerStatus.active => (scheme.primaryContainer, scheme.onPrimaryContainer),
      TrainerStatus.invited => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
      TrainerStatus.deactivated => (scheme.surfaceContainerHighest, scheme.onSurfaceVariant),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
