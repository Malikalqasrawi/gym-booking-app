import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../models/trainer.dart';
import '../../models/training_category.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_card.dart';
import 'trainer_profile_screen.dart';

class TrainersScreen extends StatefulWidget {
  const TrainersScreen({super.key, required this.branch});

  final Branch branch;

  @override
  State<TrainersScreen> createState() => _TrainersScreenState();
}

class _TrainersScreenState extends State<TrainersScreen> {
  static const _priceLimits = [15, 20, 25];

  late Future<List<Trainer>> _trainersFuture;
  TrainingCategory? _category;
  String? _gender;
  int? _maxRate;

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

  /// Replaces all filters and reloads; omitted filters are cleared.
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
            return TrainerCard(
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
