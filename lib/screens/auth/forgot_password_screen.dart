import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../services/auth_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/password_field.dart';
import '../../widgets/theme_toggle_button.dart';

/// Step 1 emails a reset code, step 2 sets a new password with it. Pops with the email once the
/// password is changed, so the login screen can fill it in.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key, this.email = ''});

  final String email;

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  static const _resendWaitSeconds = 60; // same as the backend's cooldown

  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.email);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  Timer? _timer;
  int _secondsLeft = 0;

  String get _email => _emailController.text.trim();

  @override
  void dispose() {
    _timer?.cancel();
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _timer?.cancel();
    _secondsLeft = _resendWaitSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    if (!_codeSent && !_emailFormKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    setState(() => _loading = true);
    try {
      final message = await authApi.forgotPassword(_email);
      if (!mounted) return;
      showInfo(context, message);
      setState(() {
        _codeSent = true;
        _codeController.clear();
        _startResendTimer();
      });
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _reset() async {
    if (!_resetFormKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final navigator = Navigator.of(context);
    setState(() => _loading = true);
    try {
      await authApi.resetPassword(email: _email, code: _codeController.text, password: _passwordController.text);
      navigator.pop(_email);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _changeEmail() {
    _timer?.cancel();
    setState(() {
      _codeSent = false;
      _secondsLeft = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(actions: const [ThemeToggleButton()]),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthHeader(
                icon: Icons.lock_reset,
                title: 'Reset your password',
                subtitle: _codeSent
                    ? 'Enter the 6-digit code we emailed to $_email and choose a new password.'
                    : 'Enter your account\'s email and we\'ll send you a code to reset your password.',
              ),
              const SizedBox(height: 28),
              if (_codeSent) _buildResetForm() else _buildEmailForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            onFieldSubmitted: (_) => _sendCode(),
            validator: Validators.email,
            decoration: AppTheme.input(context, label: 'Email', icon: Icons.email_outlined),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _sendCode,
            child: _loading
                ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Send code'),
          ),
        ],
      ),
    );
  }

  Widget _buildResetForm() {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textInputAction: TextInputAction.next,
            maxLength: 6,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: Validators.code,
            decoration: AppTheme.input(context, label: 'Reset code', icon: Icons.pin_outlined)
                .copyWith(counterText: ''),
          ),
          const SizedBox(height: 14),
          PasswordField(
            controller: _passwordController,
            label: 'New password',
            validator: Validators.password,
          ),
          const SizedBox(height: 14),
          PasswordField(
            controller: _confirmController,
            label: 'Confirm new password',
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _reset(),
            validator: (value) => value == _passwordController.text ? null : "Passwords don't match",
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _loading ? null : _reset,
            child: _loading
                ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                : const Text('Change password'),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Didn't get it?", style: TextStyle(color: muted)),
              TextButton(
                onPressed: _secondsLeft > 0 || _loading ? null : _sendCode,
                child: Text(_secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend code'),
              ),
            ],
          ),
          TextButton(
            onPressed: _loading ? null : _changeEmail,
            child: const Text('Use a different email'),
          ),
          if (kDebugMode) ...[
            const SizedBox(height: 8),
            Text(
              'Debug build: with console email mode, the code is printed in the backend log.',
              textAlign: TextAlign.center,
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
