import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../models/branch.dart';
import '../../services/admin_api.dart';
import '../../services/booking_api.dart';
import '../../utils/messages.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import 'branch_form_screen.dart';

class AdminBranchesScreen extends StatefulWidget {
  const AdminBranchesScreen({super.key});

  @override
  State<AdminBranchesScreen> createState() => _AdminBranchesScreenState();
}

class _AdminBranchesScreenState extends State<AdminBranchesScreen> {
  late Future<(List<Branch>, List<AdminTrainer>)> _data;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final branches = context.read<BookingApi>().getBranches();
    final trainers = context.read<AdminApi>().trainers();
    _data = (branches, trainers).wait;
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _data;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  /// The form pops with a message when it saved or deleted something.
  Future<void> _openForm([Branch? branch]) async {
    final done = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => BranchFormScreen(branch: branch)),
    );
    if (!mounted || done == null) return;
    showInfo(context, done);
    setState(_load);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Branches'), actions: const [ThemeToggleButton()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Add branch'),
      ),
      body: FutureBuilder<(List<Branch>, List<AdminTrainer>)>(
        future: _data,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return LoadError(message: 'Could not load the branches', onRetry: () => setState(_load));
          }
          final (branches, trainers) = snapshot.data!;
          int trainersAt(Branch branch) =>
              trainers.where((t) => t.branchId == branch.id && t.status != TrainerStatus.deactivated).length;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // room for the button
              children: [
                if (branches.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(child: Text('No branches yet.')),
                  ),
                for (final branch in branches)
                  _BranchRow(branch: branch, trainers: trainersAt(branch), onTap: () => _openForm(branch)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  const _BranchRow({required this.branch, required this.trainers, required this.onTap});

  final Branch branch;
  final int trainers;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Icon(Icons.store_mall_directory_outlined, color: scheme.primary),
        title: Text(branch.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '${branch.address}, ${branch.city}\nOpen ${branch.hours} · $trainers trainer${trainers == 1 ? '' : 's'}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
