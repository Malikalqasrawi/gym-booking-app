import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gym_booking/widgets/auth_switch_prompt.dart';

/// A small widget test: the "Already have an account? Log in" row calls its callback when tapped.
void main() {
  testWidgets('AuthSwitchPrompt calls onPressed when tapped', (tester) async {
    var tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AuthSwitchPrompt(
          question: 'Already have an account?',
          actionLabel: 'Log in',
          onPressed: () => tapped = true,
        ),
      ),
    ));

    expect(find.text('Already have an account?'), findsOneWidget);
    await tester.tap(find.text('Log in'));
    expect(tapped, isTrue);
  });
}
