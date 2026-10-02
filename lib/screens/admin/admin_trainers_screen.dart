import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../utils/messages.dart';
import '../../utils/money.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import '../../widgets/trainer_avatar.dart';
import '../../widgets/trainer_status_chip.dart';
import 'admin_trainer_detail_screen.dart';
import 'trainer_form_screen.dart';

class AdminTrainersScreen extends StatefulWidget {
  const AdminTrainersScreen({super.key});

  @override
  State<AdminTrainersScreen> createState() => _AdminTrainersScreenState();
}

class _AdminTrainersScreenState extends State<AdminTrainersScreen> {
  late Future<List<AdminTrainer>> _trainers;
  TrainerStatus? _filter; // null shows everyone

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _trainers = context.read<AdminApi>().trainers();
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _trainers;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<AdminTrainer>(
      MaterialPageRoute(builder: (_) => const TrainerFormScreen()),
    );
    if (!mounted || created == null) return;
    showInfo(context, 'Invite sent to ${created.email}.');
    setState(_load);
  }

  Future<void> _open(AdminTrainer trainer) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AdminTrainerDetailScreen(trainerId: trainer.id)),
    );
    if (!mounted) return;
    setState(_load); // the trainer may have been edited or deactivated
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trainers'), actions: const [ThemeToggleButton()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Add trainer'),
      ),
      body: FutureBuilder<List<AdminTrainer>>(
        future: _trainers,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load the trainers',
              onRetry: () => setState(_load),
            );
          }

          final all = snapshot.data!;
          final shown = _filter == null ? all : all.where((t) => t.status == _filter).toList();

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // room for the button
              children: [
                Wrap(
                  spacing: 8,
                  children: [
                    _filterChip('All', null, all.length),
                    for (final status in TrainerStatus.values)
                      _filterChip(status.label, status, all.where((t) => t.status == status).length),
                  ],
                ),
                const SizedBox(height: 8),
                if (shown.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No trainers here.')),
                  ),
                for (final trainer in shown) _TrainerRow(trainer: trainer, onTap: () => _open(trainer)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _filterChip(String label, TrainerStatus? status, int count) => ChoiceChip(
        label: Text('$label ($count)'),
        selected: _filter == status,
        onSelected: (_) => setState(() => _filter = status),
      );
}

class _TrainerRow extends StatelessWidget {
  const _TrainerRow({required this.trainer, required this.onTap});

  final AdminTrainer trainer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final muted = TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final details = [
      if (trainer.branchName != null) trainer.branchName!,
      if (trainer.category != null) trainer.category!.label,
      if (trainer.hourlyRate != null) '${formatJod(trainer.hourlyRate!)}/h',
    ].join(' · ');

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: TrainerAvatar(id: trainer.id, name: trainer.fullName, radius: 22),
        title: Text(trainer.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(details, style: muted),
        trailing: TrainerStatusChip(status: trainer.status),
      ),
    );
  }
}
