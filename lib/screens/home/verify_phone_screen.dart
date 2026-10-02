import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../services/auth_api.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/phones.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_header.dart';
import 'change_phone_screen.dart';

/// Opens [VerifyPhoneScreen]. True once the phone number is confirmed.
Future<bool> confirmPhoneNumber(BuildContext context) async {
  final confirmed = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const VerifyPhoneScreen()),
  );
  return confirmed == true;
}

/// Texts a 6-digit code to the user's phone number and checks it. Members do this once before
/// their first booking, and again after changing their number. Pops with true when confirmed.
class VerifyPhoneScreen extends StatefulWidget {
  const VerifyPhoneScreen({super.key});

  @override
  State<VerifyPhoneScreen> createState() => _VerifyPhoneScreenState();
}

class _VerifyPhoneScreenState extends State<VerifyPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _sending = false;
  bool _confirming = false;
  int _secondsLeft = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // The member came here to confirm, so the first code goes out right away.
    WidgetsBinding.instance.addPostFrameCallback((_) => _sendCode());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  /// Disables "Resend" until the backend allows another code.
  void _startResendTimer(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) timer.cancel();
      });
    });
  }

  Future<void> _sendCode() async {
    final authApi = context.read<AuthApi>();
    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);

    setState(() => _sending = true);
    try {
      final wait = await authApi.sendPhoneCode();
      if (!mounted) return;
      _codeController.clear();
      _startResendTimer(wait);
    } on ApiException catch (e) {
      if (!mounted) return;
      switch (e.code) {
        case 'PHONE_ALREADY_VERIFIED':
          await session.reloadUser();
          navigator.pop(true);
        case 'RESEND_TOO_SOON':
          // A code went out a moment ago and still works.
          showInfo(context, 'We already texted you a code. Enter it below.');
          _startResendTimer(60);
        default:
          showError(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _confirm() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);
    setState(() => _confirming = true);
    try {
      await session.confirmPhone(_codeController.text);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _changeNumber() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const ChangePhoneScreen()),
    );
    if (changed != true || !mounted) return;
    if (context.read<SessionController>().user?.phoneVerified ?? false) {
      Navigator.of(context).pop(true); // back to a number that was already confirmed
      return;
    }
    _timer?.cancel();
    setState(() => _secondsLeft = 0);
    await _sendCode(); // to the new number
  }

  @override
  Widget build(BuildContext context) {
    final phone = Phones.display(context.watch<SessionController>().user?.phone ?? '');
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm your phone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AuthHeader(
                  icon: Icons.sms_outlined,
                  title: 'Check your messages',
                  subtitle: _sending
                      ? 'Sending a code to\n$phone…'
                      : 'We texted a 6-digit code to\n$phone',
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _codeController,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.code,
                  onFieldSubmitted: (_) => _confirm(),
                  decoration: AppTheme.input(context, label: 'Code', icon: Icons.pin_outlined)
                      .copyWith(counterText: ''),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _confirming ? null : _confirm,
                  child: _confirming
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Confirm'),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Didn't get it?", style: TextStyle(color: muted)),
                    TextButton(
                      onPressed: _sending || _secondsLeft > 0 ? null : _sendCode,
                      child: Text(_secondsLeft > 0 ? 'Resend in ${_secondsLeft}s' : 'Resend code'),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _sending ? null : _changeNumber,
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Wrong number? Change it'),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Debug build: without Twilio keys, the code is printed in the backend log.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: muted),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
