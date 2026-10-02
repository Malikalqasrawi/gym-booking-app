import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/review.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../utils/messages.dart';
import '../../widgets/load_error.dart';
import '../../widgets/review_tile.dart';
import '../../widgets/text_prompt_dialog.dart';
import '../../widgets/theme_toggle_button.dart';

/// Every member review, newest first. The admin can hide one with a reason (the member is
/// emailed it) and show it again.
class AdminReviewsScreen extends StatefulWidget {
  const AdminReviewsScreen({super.key});

  @override
  State<AdminReviewsScreen> createState() => _AdminReviewsScreenState();
}

class _AdminReviewsScreenState extends State<AdminReviewsScreen> {
  bool _hiddenOnly = false;
  late Future<List<Review>> _future;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _future = context.read<AdminApi>().reviews(hidden: _hiddenOnly ? true : null);
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _future;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  Future<void> _hide(Review review) async {
    final reason = await showTextPrompt(
      context,
      title: 'Hide this review?',
      message: "It disappears from ${review.trainerName}'s profile and rating. "
          '${review.memberName} is emailed the reason.',
      label: 'Reason',
      action: 'Hide review',
      maxLength: 300,
      destructive: true,
    );
    if (reason == null || !mounted) return;
    await _update(review, (api) => api.hideReview(review.id, reason), 'Review hidden. The member was emailed.');
  }

  Future<void> _show(Review review) =>
      _update(review, (api) => api.showReview(review.id), "Review shown again on ${review.trainerName}'s profile.");

  Future<void> _update(Review review, Future<Review> Function(AdminApi api) send, String doneText) async {
    final api = context.read<AdminApi>();
    setState(() => _busyId = review.id);
    try {
      await send(api);
      if (!mounted) return;
      showInfo(context, doneText);
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
    }
    if (!mounted) return;
    setState(() {
      _busyId = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews'),
        actions: const [ThemeToggleButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: false, label: Text('All')),
                  ButtonSegment(value: true, label: Text('Hidden'), icon: Icon(Icons.visibility_off_outlined)),
                ],
                selected: {_hiddenOnly},
                onSelectionChanged: (selection) => setState(() {
                  _hiddenOnly = selection.first;
                  _load();
                }),
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Review>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  final error = snapshot.error;
                  return LoadError(
                    message: error is ApiException ? error.message : 'Could not load the reviews.',
                    onRetry: () => setState(_load),
                  );
                }
                final reviews = snapshot.data!;
                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (reviews.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 48),
                          child: Text(_hiddenOnly ? 'No hidden reviews.' : 'No reviews yet.',
                              textAlign: TextAlign.center),
                        ),
                      for (final review in reviews) ...[
                        ReviewTile(review: review, showTrainer: true, footer: _actions(review)),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _actions(Review review) {
    if (_busyId == review.id) {
      return const Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    final enabled = _busyId == null;
    return Align(
      alignment: Alignment.centerRight,
      child: review.hidden
          ? TextButton.icon(
              onPressed: enabled ? () => _show(review) : null,
              icon: const Icon(Icons.visibility_outlined, size: 18),
              label: const Text('Show again'),
            )
          : TextButton.icon(
              onPressed: enabled ? () => _hide(review) : null,
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              icon: const Icon(Icons.visibility_off_outlined, size: 18),
              label: const Text('Hide'),
            ),
    );
  }
}
