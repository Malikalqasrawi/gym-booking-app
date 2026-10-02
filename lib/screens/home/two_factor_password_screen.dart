import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../services/auth_api.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/password_field.dart';
import '../../widgets/theme_toggle_button.dart';
import '../auth/two_factor_setup_screen.dart';

enum TwoFactorChange { turnOn, newPhone, turnOff }

/// Asks for the password, and for a code when two-factor authentication is already on, before
/// changing it. Turning on and moving to a new phone continue with the setup screen.
class TwoFactorPasswordScreen extends StatefulWidget {
  const TwoFactorPasswordScreen({super.key, required this.change});

  final TwoFactorChange change;

  @override
  State<TwoFactorPasswordScreen> createState() => _TwoFactorPasswordScreenState();
}

class _TwoFactorPasswordScreenState extends State<TwoFactorPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();
  bool _saving = false;

  bool get _needsCode => widget.change != TwoFactorChange.turnOn;

  @override
  void dispose() {
    _passwordController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final change = widget.change;
    final password = _passwordController.text;
    final code = _needsCode ? _codeController.text.trim() : null;

    setState(() => _saving = true);
    try {
      if (change == TwoFactorChange.turnOff) {
        await authApi.disableTwoFactor(password: password, code: code!);
        await session.setTwoFactorEnabled(false);
        navigator.pop();
        messenger.showSnackBar(const SnackBar(content: Text('Two-factor authentication is off.')));
        return;
      }

      final setup = await authApi.startTwoFactorSetup(password: password, code: code);
      navigator.pushReplacement(MaterialPageRoute(
        builder: (_) => TwoFactorSetupScreen(
          setup: setup,
          confirm: authApi.confirmTwoFactorSetup,
          onDone: (_) async {
            await session.setTwoFactorEnabled(true);
            navigator.popUntil((route) => route.isFirst); // back to the Profile tab
            messenger.showSnackBar(SnackBar(
              content: Text(change == TwoFactorChange.turnOn
                  ? 'Two-factor authentication is on.'
                  : 'Your new phone is set up. Codes from the old one no longer work.'),
            ));
          },
        ),
      ));
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (title, intro, button) = switch (widget.change) {
      TwoFactorChange.turnOn => (
          'Turn on two-factor',
          'When you log in, you will enter your password and then a code from an authenticator app '
              "on your phone. Someone who learns your password still can't log in.",
          'Continue',
        ),
      TwoFactorChange.newPhone => (
          'Set up a new phone',
          'Enter a code from your current authenticator app. If you no longer have it, use a recovery '
              'code. You will also get new recovery codes.',
          'Continue',
        ),
      TwoFactorChange.turnOff => (
          'Turn off two-factor',
          'Logging in will only need your password. Enter a code from your authenticator app, or a '
              'recovery code, to confirm.',
          'Turn off',
        ),
    };

    return Scaffold(
      appBar: AppBar(title: Text(title), actions: const [ThemeToggleButton()]),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(intro, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 20),
              PasswordField(
                controller: _passwordController,
                label: 'Password',
                textInputAction: _needsCode ? TextInputAction.next : TextInputAction.done,
                onSubmitted: _needsCode ? null : (_) => _continue(),
                validator: (value) => Validators.required(value, 'Password'),
              ),
              if (_needsCode) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  autocorrect: false,
                  enableSuggestions: false,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _continue(),
                  validator: Validators.twoFactorCode,
                  decoration: AppTheme.input(
                    context,
                    label: 'Code from the app, or a recovery code',
                    icon: Icons.pin_outlined,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _continue,
                child: _saving
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
