import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/session_controller.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';
import 'sign_up_screen.dart';

/// The app's first widget. It decides what to show:
///
///   logged in?  → HomeScreen
///   otherwise   → Sign up screen (or Login screen, if the user tapped "Log in")
///
/// Because it WATCHES SessionController, it rebuilds by itself after login / logout.
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
      // After a logout, show Login (not Sign up): this person already has an account.
      _showLogin = true;
      return const HomeScreen();
    }

    if (_showLogin) {
      return LoginScreen(onSwitchToSignUp: () => setState(() => _showLogin = false));
    }
    return SignUpScreen(onSwitchToLogin: () => setState(() => _showLogin = true));
  }
}
