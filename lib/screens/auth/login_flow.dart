import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/auth_api.dart';
import '../../state/session_controller.dart';
import 'two_factor_code_screen.dart';
import 'two_factor_setup_screen.dart';

/// After the first login step (password or Google): starts the session, or asks for a code from
/// the authenticator app, or sets one up first (an admin's first login).
Future<void> continueLogin(BuildContext context, LoginResult result) async {
  final controller = context.read<SessionController>();
  final authApi = context.read<AuthApi>();
  final navigator = Navigator.of(context);

  switch (result) {
    case LoggedIn(:final session):
      await controller.startSession(session); // AuthGate then shows the app
    case TwoFactorChallenge(:final challengeToken, setupRequired: true):
      await _setUpAuthenticator(navigator, authApi, controller, challengeToken);
    case TwoFactorChallenge(:final challengeToken):
      navigator.push(MaterialPageRoute(
        builder: (_) => TwoFactorCodeScreen(challengeToken: challengeToken),
      ));
  }
}

/// An admin's first login: connect an authenticator app, then the session starts.
Future<void> _setUpAuthenticator(
  NavigatorState navigator,
  AuthApi authApi,
  SessionController controller,
  String challengeToken,
) async {
  final setup = await authApi.startLoginSetup(challengeToken);
  AuthResult? newSession;
  navigator.push(MaterialPageRoute(
    builder: (_) => TwoFactorSetupScreen(
      setup: setup,
      reason: 'Admins must use two-factor authentication. Set it up once to finish logging in.',
      confirm: (code) async {
        final confirmed = await authApi.confirmLoginSetup(challengeToken: challengeToken, code: code);
        newSession = confirmed.session;
        return confirmed.recoveryCodes;
      },
      onDone: (_) async {
        await controller.startSession(newSession!);
        navigator.popUntil((route) => route.isFirst); // AuthGate, below, now shows the app
      },
    ),
  ));
}
