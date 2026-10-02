import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../home/main_shell.dart';
import 'blocked_times_screen.dart';

/// Admin section of the home screen: trainer counts and the ways into each admin area.
class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  late Future<List<AdminTrainer>> _trainers;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _trainers = context.read<AdminApi>().trainers();
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (!mounted) return;
    setState(_load); // trainer counts may have changed there
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return FutureBuilder<List<AdminTrainer>>(
      future: _trainers,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          final error = snapshot.error;
          return ListTile(
            leading: const Icon(Icons.cloud_off_outlined),
            title: Text(error is ApiException ? error.message : 'Could not load the trainers'),
            trailing: TextButton(onPressed: () => setState(_load), child: const Text('Retry')),
          );
        }

        final trainers = snapshot.data!;
        int count(TrainerStatus status) => trainers.where((t) => t.status == status).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Trainers', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _Stat(value: count(TrainerStatus.active), label: 'active', icon: Icons.verified_outlined)),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    value: count(TrainerStatus.invited),
                    label: 'invite pending',
                    icon: Icons.mark_email_unread_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _Stat(
                    value: count(TrainerStatus.deactivated),
                    label: 'deactivated',
                    icon: Icons.person_off_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => TabSwitcher.goTo(context, AppTab.trainers),
              icon: const Icon(Icons.groups_outlined),
              label: const Text('Manage trainers'),
            ),
            const SizedBox(height: 16),
            _AdminLink(
              icon: Icons.event_note_outlined,
              title: 'Bookings',
              subtitle: 'Every session, and cancelling one with a full refund',
              onTap: () => TabSwitcher.goTo(context, AppTab.bookings),
            ),
            _AdminLink(
              icon: Icons.event_busy_outlined,
              title: 'Blocked times',
              subtitle: 'Close a branch or give a trainer time off',
              onTap: () => _open(const BlockedTimesScreen()),
            ),
            _AdminLink(
              icon: Icons.store_mall_directory_outlined,
              title: 'Branches',
              subtitle: 'Add or edit branches, opening hours and location',
              onTap: () => TabSwitcher.goTo(context, AppTab.branches),
            ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.icon});

  final int value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(height: 6),
          Text('$value', style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}

class _AdminLink extends StatelessWidget {
  const _AdminLink({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: scheme.primary),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
