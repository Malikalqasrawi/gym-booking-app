import 'package:flutter/material.dart';

import '../models/review.dart';
import '../utils/dates.dart';
import 'star_rating.dart';

/// One review: stars, who and when, the comment and the trainer's answer. [footer] adds actions,
/// e.g. the trainer's Reply button or the admin's Hide button.
class ReviewTile extends StatelessWidget {
  const ReviewTile({super.key, required this.review, this.showTrainer = false, this.footer});

  final Review review;
  final bool showTrainer;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant, fontSize: 12);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRating(rating: review.rating),
              const Spacer(),
              Text(prettyDate(review.createdAt), style: muted),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            showTrainer ? '${review.memberName} about ${review.trainerName}' : review.memberName,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          if (review.comment != null) ...[
            const SizedBox(height: 4),
            Text(review.comment!),
          ],
          if (review.reply != null)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.only(left: 10),
              decoration: BoxDecoration(border: Border(left: BorderSide(color: scheme.primary, width: 3))),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reply from ${review.trainerName.split(' ').first}', style: muted),
                  Text(review.reply!),
                ],
              ),
            ),
          if (review.hidden) ...[
            const SizedBox(height: 10),
            Text('Hidden: ${review.hiddenReason ?? ''}',
                style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 12)),
          ],
          if (footer != null) ...[const SizedBox(height: 8), footer!],
        ],
      ),
    );
  }
}
