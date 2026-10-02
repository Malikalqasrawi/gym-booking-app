import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/blocked_time.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../utils/messages.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import 'blocked_time_form_screen.dart';

/// Branch closures and trainers' time off that haven't ended yet.
class BlockedTimesScreen extends StatefulWidget {
  const BlockedTimesScreen({super.key});

  @override
  State<BlockedTimesScreen> createState() => _BlockedTimesScreenState();
}

class _BlockedTimesScreenState extends State<BlockedTimesScreen> {
  late Future<List<BlockedTime>> _blocks;
  int? _deletingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _blocks = context.read<AdminApi>().blockedTimes();
  }

  Future<void> _refresh() async {
    setState(_load);
    try {
      await _blocks;
    } catch (_) {
      // Shown by the FutureBuilder.
    }
  }

  Future<void> _add() async {
    final created = await Navigator.of(context).push<BlockedTimeCreated>(
      MaterialPageRoute(builder: (_) => const BlockedTimeFormScreen()),
    );
    if (!mounted || created == null) return;
    showInfo(context, switch (created.cancelledBookings) {
      0 => 'Time blocked.',
      _ => 'Time blocked. ${created.cancelledBookings} booking(s) cancelled, ${created.refundedBookings} refunded.',
    });
    setState(_load);
  }

  Future<void> _delete(BlockedTime block) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unblock this time?'),
        content: Text('${block.targetName}, ${block.whenLabel}.\n\n'
            'Members can book it again. Sessions it cancelled stay cancelled.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), // not full-width inside a dialog
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final api = context.read<AdminApi>();
    setState(() => _deletingId = block.id);
    try {
      await api.deleteBlock(block.id);
      if (mounted) showInfo(context, 'Unblocked. Members can book this time again.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
    if (!mounted) return;
    setState(() {
      _deletingId = null;
      _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked times'), actions: const [ThemeToggleButton()]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _add,
        icon: const Icon(Icons.event_busy),
        label: const Text('Block time'),
      ),
      body: FutureBuilder<List<BlockedTime>>(
        future: _blocks,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load the blocked times',
              onRetry: () => setState(_load),
            );
          }
          final blocks = snapshot.data!;
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // room for the button
              children: [
                if (blocks.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Nothing is blocked. Use Block time to close a branch or give a trainer time off.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                for (final block in blocks)
                  _BlockRow(
                    block: block,
                    deleting: _deletingId == block.id,
                    onDelete: _deletingId == null ? () => _delete(block) : null,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  const _BlockRow({required this.block, required this.deleting, required this.onDelete});

  final BlockedTime block;
  final bool deleting;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
        leading: Icon(block.isBranch ? Icons.store_mall_directory_outlined : Icons.person_outline,
            color: scheme.primary),
        title: Text(
          block.isBranch ? '${block.targetName} closed' : '${block.targetName} off',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          block.reason == null ? block.whenLabel : '${block.whenLabel}\n${block.reason}',
          style: muted,
        ),
        isThreeLine: block.reason != null,
        trailing: deleting
            ? const SizedBox.square(dimension: 24, child: CircularProgressIndicator(strokeWidth: 2.5))
            : IconButton(tooltip: 'Unblock', onPressed: onDelete, icon: const Icon(Icons.delete_outline)),
      ),
    );
  }
}
