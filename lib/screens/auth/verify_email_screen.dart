import 'dart:async';

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

/// Screen 2: type the 6-digit code that was emailed.
///
/// Flow:  POST /api/auth/verify → backend returns a token → we're logged in → Home
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendWaitSeconds = 30;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _loading = false;
  int _secondsLeft = _resendWaitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  /// Counts down 30 → 0 so the user can't spam "Resend".
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

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      final result = await authApi.verifyEmail(
        email: widget.email,
        code: _codeController.text,
      );
      // Save token + user. AuthGate (under this screen) switches to HomeScreen.
      await session.startSession(result);
      // Remove this screen so HomeScreen becomes visible.
      navigator.popUntil((route) => route.isFirst);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);   // "The code is not correct" / "The code has expired"
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final authApi = context.read<AuthApi>();
    try {
      final message = await authApi.resendCode(widget.email);
      if (!mounted) return;
      showInfo(context, message);
      _codeController.clear();
      setState(_startResendTimer);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

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
                  icon: Icons.mark_email_read_outlined,
                  title: 'Check your email',
                  subtitle: 'We sent a 6-digit code to\n${widget.email}',
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't get it?", style: TextStyle(color: muted)),
                    TextButton(
                      onPressed: _secondsLeft > 0 ? null : _resend,
                      child: Text(_secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend code'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Development tip: the code is printed in the NetBeans Output window.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
