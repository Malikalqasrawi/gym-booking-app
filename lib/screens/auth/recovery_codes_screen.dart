import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/messages.dart';

/// Shows the recovery codes right after two-factor authentication is turned on. The backend keeps
/// only their hashes, so this is the only time they can be seen.
class RecoveryCodesScreen extends StatefulWidget {
  const RecoveryCodesScreen({super.key, required this.codes, required this.onDone});

  final List<String> codes;

  /// Leaves the screen, e.g. starts the session after an admin's first login.
  final Future<void> Function(BuildContext context) onDone;

  @override
  State<RecoveryCodesScreen> createState() => _RecoveryCodesScreenState();
}

class _RecoveryCodesScreenState extends State<RecoveryCodesScreen> {
  bool _finishing = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.codes.join('\n')));
    if (mounted) showInfo(context, 'Recovery codes copied');
  }

  Future<void> _done() async {
    setState(() => _finishing = true);
    try {
      await widget.onDone(context);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    // No back button: the codes are shown only once, so leaving goes through "I saved them".
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Recovery codes'), automaticallyImplyLeading: false),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Two-factor authentication is on',
                        style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                "If you lose your phone, log in with one of these codes instead of a code from the app. "
                "Each code works once. Save them somewhere safe, such as a password manager. "
                "They won't be shown again.",
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 10,
                    children: [
                      for (final code in widget.codes)
                        SelectableText(
                          code,
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 17, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _copy,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Copy all'),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _finishing ? null : _done,
                child: _finishing
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('I saved my recovery codes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
