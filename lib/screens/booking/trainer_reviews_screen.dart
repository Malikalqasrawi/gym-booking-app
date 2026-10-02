import 'package:flutter/material.dart';

import '../../models/review.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/theme_toggle_button.dart';

/// All of a trainer's reviews, opened from "See all" on their profile.
class TrainerReviewsScreen extends StatelessWidget {
  const TrainerReviewsScreen({super.key, required this.trainerName, required this.reviews});

  final String trainerName;
  final TrainerReviews reviews;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final average = reviews.averageRating;

    return Scaffold(
      appBar: AppBar(
        title: Text(trainerName),
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (average != null)
            Column(
              children: [
                Text(average.toStringAsFixed(1), style: text.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                StarRating(rating: average.round(), size: 22),
                const SizedBox(height: 4),
                Text('${reviews.reviewCount} ${reviews.reviewCount == 1 ? 'review' : 'reviews'}',
                    style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          const SizedBox(height: 16),
          for (final review in reviews.reviews) ...[
            ReviewTile(review: review),
            const SizedBox(height: 10),
          ],
          if (reviews.reviews.length < reviews.reviewCount)
            Text('Showing the latest ${reviews.reviews.length}.',
                textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
