import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/session_controller.dart';
import '../../widgets/theme_toggle_button.dart';
import '../admin/admin_home.dart';
import 'member_home.dart';
import 'trainer_home.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final user = session.user;
    if (user == null) return const SizedBox.shrink(); // briefly null while logging out

    final roleSection = switch (user.role) {
      UserRole.member => const MemberHome(),
      UserRole.trainer => const TrainerHome(),
      UserRole.admin => const AdminHome(),
    };

    return Scaffold(
      appBar: AppBar(
        title: Text('Hi, ${user.firstName}'),
        actions: [
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<SessionController>().logout(),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _ProfileCard(user: user),
          const SizedBox(height: 16),
          roleSection,
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
