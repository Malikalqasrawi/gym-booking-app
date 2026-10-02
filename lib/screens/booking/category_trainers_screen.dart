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

/// Trainers from every branch in one category, or all trainers when [category] is null. Opened from
/// "Train by category" on the home screen.
class CategoryTrainersScreen extends StatefulWidget {
  const CategoryTrainersScreen({super.key, this.category});

  final TrainingCategory? category;

  @override
  State<CategoryTrainersScreen> createState() => _CategoryTrainersScreenState();
}

class _CategoryTrainersScreenState extends State<CategoryTrainersScreen> {
  late Future<(List<Trainer>, List<Branch>)> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _data = _fetch();
  }

  /// The branches are needed to open a trainer's profile, which shows where they work.
  Future<(List<Trainer>, List<Branch>)> _fetch() async {
    final api = context.read<BookingApi>();
    final results = await Future.wait([api.getTrainers(category: widget.category), api.getBranches()]);
    return (results[0] as List<Trainer>, results[1] as List<Branch>);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category?.label ?? 'All trainers'),
        actions: const [ThemeToggleButton()],
      ),
      body: FutureBuilder<(List<Trainer>, List<Branch>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load the trainers.',
              onRetry: () => setState(_load),
            );
          }
          final (trainers, branches) = snapshot.data!;
          if (trainers.isEmpty) {
            return const Center(child: Text('No trainers in this category yet.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: trainers.length + 1,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              if (i == 0) {
                final count = trainers.length;
                final places = trainers.map((trainer) => trainer.branchId).toSet().length;
                return Text(
                    '$count ${count == 1 ? 'trainer' : 'trainers'} at $places ${places == 1 ? 'branch' : 'branches'}',
                    style: Theme.of(context).textTheme.titleMedium);
              }
              final trainer = trainers[i - 1];
              final branch = branches.where((b) => b.id == trainer.branchId).firstOrNull;
              return TrainerCard(
                trainer: trainer,
                showBranch: true,
                onTap: branch == null
                    ? () {}
                    : () => Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => TrainerProfileScreen(trainer: trainer, branch: branch),
                        )),
              );
            },
          );
        },
      ),
    );
  }
}
