import 'package:flutter/material.dart';

import '../models/trainer.dart';
import '../utils/money.dart';
import 'star_rating.dart';
import 'trainer_avatar.dart';

/// A trainer in a list: initials, rate, specialty, stars, short bio and tags. With [showBranch], it
/// also says where they work, for lists that mix branches.
class TrainerCard extends StatelessWidget {
  const TrainerCard({super.key, required this.trainer, required this.onTap, this.showBranch = false});

  final Trainer trainer;
  final VoidCallback onTap;
  final bool showBranch;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TrainerAvatar(id: trainer.id, name: trainer.fullName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(trainer.fullName,
                              style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        if (trainer.hourlyRate != null)
                          Text('${formatJod(trainer.hourlyRate!)}/h',
                              style: text.titleSmall?.copyWith(color: scheme.primary)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text(trainer.specialty, style: TextStyle(color: scheme.primary))),
                        RatingSummary(average: trainer.averageRating, count: trainer.reviewCount, compact: true),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(trainer.bio, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (showBranch && trainer.branchName != null)
                          _Tag(icon: Icons.storefront_outlined, label: trainer.branchName!),
                        if (trainer.category != null) _Tag(icon: trainer.category!.icon, label: trainer.category!.label),
                        _Tag(icon: Icons.workspace_premium_outlined, label: '${trainer.yearsOfExperience} years'),
                        _Tag(icon: Icons.calendar_today_outlined, label: trainer.workingDaysLabel),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: scheme.surface, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
