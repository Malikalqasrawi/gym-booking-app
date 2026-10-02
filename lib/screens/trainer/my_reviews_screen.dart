import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/messages.dart';
import '../../widgets/load_error.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/star_rating.dart';
import '../../widgets/text_prompt_dialog.dart';
import '../../widgets/theme_toggle_button.dart';

/// The trainer's reviews from members. They can answer each one once and edit the answer later.
class MyReviewsScreen extends StatefulWidget {
  const MyReviewsScreen({super.key});

  @override
  State<MyReviewsScreen> createState() => _MyReviewsScreenState();
}

class _MyReviewsScreenState extends State<MyReviewsScreen> {
  late Future<TrainerReviews> _future;
  int? _savingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<BookingApi>().myReviews();
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  Future<void> _reply(Review review) async {
    final api = context.read<BookingApi>();
    final text = await showTextPrompt(
      context,
      title: review.reply == null ? 'Reply to ${review.memberName}' : 'Edit your reply',
      label: 'Your reply',
      action: 'Post reply',
      maxLength: 500,
      message: 'Your reply shows under the review on your profile.',
      initialText: review.reply,
    );
    if (text == null || !mounted) return;

    setState(() => _savingId = review.id);
    try {
      await api.replyToReview(review.id, text);
      if (!mounted) return;
      showInfo(context, 'Reply posted.');
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    }
    if (!mounted) return;
    setState(() {
      _savingId = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My reviews'),
        actions: const [ThemeToggleButton()],
      ),
      body: FutureBuilder<TrainerReviews>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load your reviews.',
              onRetry: () => setState(_load),
            );
          }
          final data = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (data.reviews.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: Text('No reviews yet.\nMembers can rate a session after it takes place.',
                        textAlign: TextAlign.center),
                  )
                else ...[
                  Center(child: RatingSummary(average: data.averageRating, count: data.reviewCount)),
                  const SizedBox(height: 16),
                ],
                for (final review in data.reviews) ...[
                  ReviewTile(
                    review: review,
                    footer: Align(
                      alignment: Alignment.centerRight,
                      child: _savingId == review.id
                          ? const Padding(
                              padding: EdgeInsets.all(8),
                              child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                            )
                          : TextButton.icon(
                              onPressed: _savingId == null ? () => _reply(review) : null,
                              icon: Icon(review.reply == null ? Icons.reply : Icons.edit_outlined, size: 18),
                              label: Text(review.reply == null ? 'Reply' : 'Edit reply'),
                            ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                if (data.reviews.isNotEmpty)
                  Text("Reviews hidden by the gym don't show here or count toward your rating.",
                      textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              ],
            ),
          );
        },
      ),
    );
  }
}
