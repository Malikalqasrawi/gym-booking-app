import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/api_exception.dart';
import '../../state/session_controller.dart';
import '../../state/theme_controller.dart';
import '../../utils/messages.dart';
import 'change_password_screen.dart';
import 'two_factor_password_screen.dart';

/// The Profile tab: the user's details, password, two-factor authentication and sessions, light or
/// dark mode, and logging out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePassword(BuildContext context) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
    );
    if (changed == true && context.mounted) {
      showInfo(context, 'Password changed. Your other devices were logged out.');
    }
  }

  /// Off: turn it on. On: set up a new phone, or turn it off (not for admins).
  Future<void> _twoFactor(BuildContext context, AppUser user) async {
    var change = TwoFactorChange.turnOn;
    if (user.twoFactorEnabled) {
      final picked = await showModalBottomSheet<TwoFactorChange>(
        context: context,
        showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.smartphone_outlined),
                title: const Text('Set up a new phone'),
                subtitle: const Text('Also gives you new recovery codes'),
                onTap: () => Navigator.pop(context, TwoFactorChange.newPhone),
              ),
              if (!user.mustUseTwoFactor)
                ListTile(
                  leading: const Icon(Icons.lock_open_outlined),
                  title: const Text('Turn off'),
                  onTap: () => Navigator.pop(context, TwoFactorChange.turnOff),
                ),
            ],
          ),
        ),
      );
      if (picked == null) return;
      change = picked;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => TwoFactorPasswordScreen(change: change)));
  }

  Future<void> _logoutEverywhere(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log out of all devices?'),
        content: const Text('Every phone where you are logged in, including this one, will need to log in again.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44)), // not full-width inside a dialog
            child: const Text('Log out everywhere'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    try {
      await context.read<SessionController>().logoutAllDevices();
    } on ApiException catch (e) {
      if (context.mounted) showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink(); // briefly null while logging out
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget card(List<Widget> children) => Card(
          elevation: 0,
          color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Column(children: children),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          card([
            ListTile(
              leading: const Icon(Icons.password),
              title: const Text('Change password'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _changePassword(context),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.phonelink_lock_outlined),
              title: const Text('Two-factor authentication'),
              subtitle: Text(!user.twoFactorEnabled
                  ? 'Off'
                  : user.mustUseTwoFactor
                      ? 'On · required for admins'
                      : 'On'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _twoFactor(context, user),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.devices_other_outlined),
              title: const Text('Log out of all devices'),
              subtitle: const Text('For example after losing a phone'),
              onTap: () => _logoutEverywhere(context),
            ),
          ]),
          const SizedBox(height: 16),
          card([
            SwitchListTile(
              secondary: const Icon(Icons.dark_mode_outlined),
              title: const Text('Dark mode'),
              value: isDark,
              onChanged: (_) => context.read<ThemeController>().toggle(Theme.of(context).brightness),
            ),
            const Divider(height: 1),
            ListTile(
              leading: Icon(Icons.logout, color: scheme.error),
              title: Text('Log out', style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600)),
              onTap: () => context.read<SessionController>().logout(),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final initials = user.fullName
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Card(
      elevation: 0,
      color: scheme.primaryContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: scheme.primary,
              child: Text(initials, style: text.titleLarge?.copyWith(color: scheme.onPrimary)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.fullName,
                      style: text.titleLarge?.copyWith(
                          color: scheme.onPrimaryContainer, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text(user.title, style: text.bodyMedium?.copyWith(color: scheme.onPrimaryContainer)),
                  const SizedBox(height: 8),
                  Text(user.email, style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
                  if (user.phone.isNotEmpty)
                    Text(user.phone, style: text.bodySmall?.copyWith(color: scheme.onPrimaryContainer)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
