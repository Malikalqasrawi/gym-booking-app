import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../state/session_controller.dart';
import '../../widgets/theme_toggle_button.dart';
import '../admin/admin_home.dart';
import 'member_home.dart';
import 'trainer_home.dart';

/// The Home tab: a greeting and the section for the user's role.
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
        actions: const [ThemeToggleButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [roleSection],
      ),
    );
  }
}
