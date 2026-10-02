import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/session_controller.dart';
import '../../state/theme_controller.dart';

/// The Profile tab: the user's details, light or dark mode, and logging out.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<SessionController>().user;
    if (user == null) return const SizedBox.shrink(); // briefly null while logging out
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
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
              ],
            ),
          ),
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
