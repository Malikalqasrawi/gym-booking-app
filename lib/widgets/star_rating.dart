import 'package:flutter/material.dart';

const starColor = Color(0xFFF5A623);

/// 1 to 5 stars, read-only.
class StarRating extends StatelessWidget {
  const StarRating({super.key, required this.rating, this.size = 16});

  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var star = 1; star <= 5; star++)
          Icon(star <= rating ? Icons.star_rounded : Icons.star_outline_rounded, size: size, color: starColor),
      ],
    );
  }
}

/// Five stars to tap; [onChanged] gets 1 to 5.
class StarRatingInput extends StatelessWidget {
  const StarRatingInput({super.key, required this.rating, required this.onChanged});

  final int rating; // 0 until the member picks
  final ValueChanged<int> onChanged;

  static const _labels = ['Tap a star', 'Poor', 'Fair', 'Good', 'Very good', 'Excellent'];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var star = 1; star <= 5; star++)
              IconButton(
                tooltip: '$star ${star == 1 ? 'star' : 'stars'}',
                iconSize: 40,
                onPressed: () => onChanged(star),
                icon: Icon(star <= rating ? Icons.star_rounded : Icons.star_outline_rounded, color: starColor),
              ),
          ],
        ),
        Text(_labels[rating], style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

/// "★ 4.8 · 12 reviews", or "★ 4.8 (12)" when [compact]. Nothing for a trainer without reviews.
class RatingSummary extends StatelessWidget {
  const RatingSummary({super.key, required this.average, required this.count, this.compact = false});

  final double? average;
  final int count;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (average == null || count == 0) return const SizedBox.shrink();
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star_rounded, size: compact ? 14 : 18, color: starColor),
        const SizedBox(width: 2),
        Text(average!.toStringAsFixed(1),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: compact ? 12 : 14)),
        Text(compact ? ' ($count)' : ' · $count ${count == 1 ? 'review' : 'reviews'}',
            style: TextStyle(color: muted, fontSize: compact ? 12 : 14)),
      ],
    );
  }
}
