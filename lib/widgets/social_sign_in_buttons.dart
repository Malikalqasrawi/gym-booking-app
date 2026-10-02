import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth/login_flow.dart';
import '../services/api_exception.dart';
import '../services/auth_api.dart';
import '../services/google_auth.dart';
import '../utils/messages.dart';

/// "Continue with" Google and Apple. Google signs members in or up; Apple sign-in needs a paid
/// Apple Developer account, so its button only says so.
class SocialSignInButtons extends StatefulWidget {
  const SocialSignInButtons({super.key});

  @override
  State<SocialSignInButtons> createState() => _SocialSignInButtonsState();
}

class _SocialSignInButtonsState extends State<SocialSignInButtons> {
  bool _busy = false;

  Future<void> _google() async {
    if (!GoogleAuth.isConfigured) {
      showInfo(context, "Google sign-in isn't set up in this build of the app.");
      return;
    }
    final authApi = context.read<AuthApi>();
    setState(() => _busy = true);
    try {
      final idToken = await GoogleAuth.idToken();
      if (idToken == null || !mounted) return; // the account picker was closed
      final result = await authApi.loginWithGoogle(idToken);
      if (!mounted) return;
      await continueLogin(context, result);
    } on GoogleAuthException catch (e) {
      if (mounted) showError(context, e.message);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Row(
          children: [
            const Expanded(child: Divider()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text('or continue with', style: TextStyle(color: muted)),
            ),
            const Expanded(child: Divider()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: _busy
                    ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.g_mobiledata, size: 30),
                label: const Text('Google'),
                onPressed: _busy ? null : _google,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.apple),
                label: const Text('Apple'),
                onPressed: () =>
                    showInfo(context, 'Apple sign-in needs a paid Apple Developer account'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
