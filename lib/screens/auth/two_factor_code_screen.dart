import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../services/auth_api.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/theme_toggle_button.dart';

/// Second login step for accounts with two-factor authentication: the code from the authenticator
/// app, or a recovery code when the phone isn't at hand.
class TwoFactorCodeScreen extends StatefulWidget {
  const TwoFactorCodeScreen({super.key, required this.challengeToken});

  /// From the login answer; proves the password was right.
  final String challengeToken;

  @override
  State<TwoFactorCodeScreen> createState() => _TwoFactorCodeScreenState();
}

class _TwoFactorCodeScreenState extends State<TwoFactorCodeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _useRecoveryCode = false;
  bool _loading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      final result = await authApi.loginWithCode(
        challengeToken: widget.challengeToken,
        code: _codeController.text.trim(),
      );
      await session.startSession(result);
      // AuthGate, below this route, now shows the app.
      navigator.popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
      // Took too long, or the password was changed meanwhile: back to the password.
      if (e.code == 'LOGIN_EXPIRED') navigator.pop();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _switchCodeType() {
    setState(() {
      _useRecoveryCode = !_useRecoveryCode;
      _codeController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [ThemeToggleButton()]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  icon: Icons.phonelink_lock_outlined,
                  title: 'Enter your code',
                  subtitle: _useRecoveryCode
                      ? 'Enter one of the recovery codes you saved when you turned on two-factor '
                          'authentication. Each code works once.'
                      : 'Open your authenticator app and enter the 6-digit code for Gym Booking.',
                ),
                const SizedBox(height: 28),
                if (_useRecoveryCode)
                  TextFormField(
                    key: const ValueKey('recovery-code'),
                    controller: _codeController,
                    autofocus: true,
                    autocorrect: false,
                    enableSuggestions: false,
                    textAlign: TextAlign.center,
                    maxLength: 11,
                    style: const TextStyle(fontSize: 22, letterSpacing: 2, fontWeight: FontWeight.bold),
                    validator: Validators.recoveryCode,
                    onFieldSubmitted: (_) => _verify(),
                    decoration: AppTheme.input(context, label: 'Recovery code', icon: Icons.key_outlined)
                        .copyWith(counterText: ''),
                  )
                else
                  TextFormField(
                    key: const ValueKey('app-code'),
                    controller: _codeController,
                    autofocus: true,
                    keyboardType: TextInputType.number,
                    autofillHints: const [AutofillHints.oneTimeCode],
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: Validators.code,
                    onFieldSubmitted: (_) => _verify(),
                    decoration: AppTheme.input(context, label: 'Code', icon: Icons.pin_outlined)
                        .copyWith(counterText: ''),
                  ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _verify,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Verify'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _loading ? null : _switchCodeType,
                  child: Text(_useRecoveryCode
                      ? 'Use the authenticator app instead'
                      : "Don't have your phone? Use a recovery code"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
