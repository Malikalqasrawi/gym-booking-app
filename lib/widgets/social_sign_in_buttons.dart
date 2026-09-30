import 'package:flutter/material.dart';

import '../utils/messages.dart';

/// "or continue with" + Google and Apple buttons.
/// They're placeholders in Stage 1. Google gets wired up in Stage 6.
/// (Apple sign-in requires a paid Apple Developer account.)
class SocialSignInButtons extends StatelessWidget {
  const SocialSignInButtons({super.key});

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
                icon: const Icon(Icons.g_mobiledata, size: 30),
                label: const Text('Google'),
                onPressed: () => showInfo(context, 'Google sign-in is coming in Stage 6'),
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
