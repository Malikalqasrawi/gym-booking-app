import 'package:flutter/material.dart';

/// "Already have an account? Log in"  /  "Don't have an account? Sign up"
class AuthSwitchPrompt extends StatelessWidget {
  const AuthSwitchPrompt({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onPressed,
  });

  final String question;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(question, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
        TextButton(
          onPressed: onPressed,
          child: Text(actionLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
