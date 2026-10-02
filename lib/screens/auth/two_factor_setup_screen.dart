import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/two_factor.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/theme_toggle_button.dart';
import 'recovery_codes_screen.dart';

/// Connects an authenticator app: shows the QR code and the setup key, then checks a code from the
/// app. Used at an admin's first login and from the Profile tab.
class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({
    super.key,
    required this.setup,
    required this.confirm,
    required this.onDone,
    this.reason,
  });

  final TwoFactorSetup setup;

  /// Sends the code from the app to the backend and returns the recovery codes.
  final Future<List<String>> Function(String code) confirm;

  /// Called from the recovery codes screen once the user has saved them.
  final Future<void> Function(BuildContext context) onDone;

  /// Shown at the top, e.g. why an admin has to do this.
  final String? reason;

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _copyKey() async {
    await Clipboard.setData(ClipboardData(text: widget.setup.secret));
    if (mounted) showInfo(context, 'Setup key copied');
  }

  Future<void> _turnOn() async {
    if (!_formKey.currentState!.validate()) return;

    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final codes = await widget.confirm(_codeController.text);
      // Replaces this screen, so going back can't show the old QR code again.
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => RecoveryCodesScreen(codes: codes, onDone: widget.onDone),
      ));
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.message);
      // An admin's login took too long: start again from the password.
      if (e.code == 'LOGIN_EXPIRED') navigator.popUntil((route) => route.isFirst);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up two-factor'), actions: const [ThemeToggleButton()]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.reason != null) ...[
                Card(
                  elevation: 0,
                  color: scheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Text(widget.reason!, style: TextStyle(color: scheme.onPrimaryContainer)),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              const _Step(
                number: 1,
                text: 'Install an authenticator app on your phone, such as Google Authenticator '
                    'or Microsoft Authenticator.',
              ),
              const _Step(
                number: 2,
                text: 'In the app, add an account and scan this QR code. If the app is on this '
                    'phone, copy the setup key below and paste it into the app instead.',
              ),
              const SizedBox(height: 8),
              Center(
                // White behind the code in dark mode too, so cameras can read it.
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                  child: QrImageView(
                    data: widget.setup.otpauthUri,
                    size: 200,
                    backgroundColor: Colors.white,
                    semanticsLabel: 'QR code for your authenticator app',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text('Setup key', style: text.labelLarge?.copyWith(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: SelectableText(
                      widget.setup.groupedSecret,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy setup key',
                    icon: const Icon(Icons.copy_outlined),
                    onPressed: _copyKey,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const _Step(number: 3, text: 'Enter the 6-digit code the app shows for Gym Booking.'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                style: const TextStyle(fontSize: 28, letterSpacing: 12, fontWeight: FontWeight.bold),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: Validators.code,
                onFieldSubmitted: (_) => _turnOn(),
                decoration: AppTheme.input(context, label: 'Code', icon: Icons.pin_outlined)
                    .copyWith(counterText: ''),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _turnOn,
                child: _saving
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Turn on'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: scheme.primary,
            child: Text('$number', style: TextStyle(color: scheme.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
