import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../home/main_shell.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// Shows the app's tabs ([MainShell]) when logged in, otherwise the sign-up or login screen.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    if (session.isLoggedIn) {
      // After logout, show Login rather than Sign up: this user already has an account.
      _showLogin = true;
      return const MainShell();
    }

    if (_showLogin) {
      return LoginScreen(onSwitchToSignUp: () => setState(() => _showLogin = false));
    }
    return SignUpScreen(onSwitchToLogin: () => setState(() => _showLogin = true));
  }
}
