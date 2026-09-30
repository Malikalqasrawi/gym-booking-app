import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../models/trainer.dart';
import '../../models/training_category.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../utils/money.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_avatar.dart';
import 'trainer_profile_screen.dart';

/// Step 2 of booking: pick a trainer at the chosen branch, with filters.
///
///   GET /api/branches/{id}/trainers?category=YOGA&gender=FEMALE&maxRate=20
///
/// Every time a filter chip changes, we ask the backend again with the new filters.
class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key, required this.branch});

  final Branch branch;

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  static const _priceLimits = [15, 20, 25]; // "Up to 15 JOD/h" ...

  late Future<List<Trainer>> _trainersFuture;
  TrainingCategory? _category; // null = all
  String? _gender; // null = any, "FEMALE", "MALE"
  int? _maxRate; // null = any price

  bool get _hasFilters => _category != null || _gender != null || _maxRate != null;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _trainersFuture = context.read<BookingApi>().getTrainersForBranch(
          widget.branch.id,
          category: _category,
          gender: _gender,
          maxRate: _maxRate,
        );
  }

  /// Changes the filters and reloads. Tapping the selected chip again turns it off.
  void _setFilters({TrainingCategory? category, String? gender, int? maxRate}) {
    setState(() {
      _category = category;
      _gender = gender;
      _maxRate = maxRate;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.branch.name),
        actions: const [ThemeToggleButton()],
      ),
      body: Column(
        children: [
          _buildCategoryChips(),
          _buildGenderAndPriceChips(),
          const Divider(height: 1),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: _category == null,
            onSelected: (_) => _setFilters(gender: _gender, maxRate: _maxRate),
          ),
          for (final category in TrainingCategory.values) ...[
            const SizedBox(width: 8),
            ChoiceChip(
              avatar: Icon(category.icon, size: 18),
              showCheckmark: false, // keep the icon visible when selected
              label: Text(category.label),
              selected: _category == category,
              onSelected: (_) => _setFilters(
                category: _category == category ? null : category,
                gender: _gender,
                maxRate: _maxRate,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGenderAndPriceChips() {
    ChoiceChip genderChip(String label, String? value) => ChoiceChip(
          label: Text(label),
          selected: _gender == value,
          onSelected: (_) => _setFilters(category: _category, gender: value, maxRate: _maxRate),
        );

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        children: [
          genderChip('Any trainer', null),
          const SizedBox(width: 8),
          genderChip('Female', 'FEMALE'),
          const SizedBox(width: 8),
          genderChip('Male', 'MALE'),
          const SizedBox(width: 20),
          for (final limit in _priceLimits) ...[
            ChoiceChip(
              label: Text('Up to $limit JOD/h'),
              selected: _maxRate == limit,
              onSelected: (_) => _setFilters(
                category: _category,
                gender: _gender,
                maxRate: _maxRate == limit ? null : limit,
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    return FutureBuilder<List<Trainer>>(
      future: _trainersFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return LoadError(
            message: error is ApiException ? error.message : 'Could not load trainers.',
            onRetry: () => setState(_load),
          );
        }
        final trainers = snapshot.data!;
        if (trainers.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_hasFilters ? 'No trainers match these filters.' : 'No trainers at this branch yet.'),
                if (_hasFilters)
                  TextButton(onPressed: () => _setFilters(), child: const Text('Clear filters')),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: trainers.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            if (i == 0) {
              final count = trainers.length;
              return Text('$count ${count == 1 ? 'trainer' : 'trainers'}',
                  style: Theme.of(context).textTheme.titleMedium);
            }
            final trainer = trainers[i - 1];
            return _TrainerCard(
              trainer: trainer,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => TrainerProfileScreen(trainer: trainer, branch: widget.branch),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainerCard extends StatelessWidget {
  const _TrainerCard({required this.trainer, required this.onTap});

  final Trainer trainer;
  final VoidCallback onTap;

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
                    Text(trainer.specialty, style: TextStyle(color: scheme.primary)),
                    const SizedBox(height: 6),
                    Text(trainer.bio, style: text.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
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
