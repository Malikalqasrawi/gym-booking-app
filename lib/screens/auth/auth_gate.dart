import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../home/main_shell.dart';
import 'add_phone_screen.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// Shows the app's tabs ([MainShell]) when logged in, otherwise the sign-up or login screen. A
/// member who signed up with Google is asked for a phone number first.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _showLogin = false;
  bool _wasLoggedIn = false;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    if (session.isLoggedIn) {
      // After logout, show Login rather than Sign up: this user already has an account.
      _showLogin = true;
      _wasLoggedIn = true;
      return session.user!.needsPhone ? const AddPhoneScreen() : const MainShell();
    }

    if (_wasLoggedIn) {
      _wasLoggedIn = false;
      // The session ended: also close any screen or dialog opened on top of the app.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      });
    }

    if (_showLogin) {
      return LoginScreen(onSwitchToSignUp: () => setState(() => _showLogin = false));
    }
    return SignUpScreen(onSwitchToLogin: () => setState(() => _showLogin = true));
  }
}
