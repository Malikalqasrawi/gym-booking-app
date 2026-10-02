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
import '../../widgets/password_field.dart';
import '../../widgets/theme_toggle_button.dart';

/// For trainers added by the gym: enter the emailed invite code and choose a password.
class AcceptInviteScreen extends StatefulWidget {
  const AcceptInviteScreen({super.key, this.email = ''});

  final String email;

  @override
  State<AcceptInviteScreen> createState() => _AcceptInviteScreenState();
}

class _AcceptInviteScreenState extends State<AcceptInviteScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.email);
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);

    setState(() => _loading = true);
    try {
      final result = await authApi.acceptInvite(
        email: _emailController.text.trim(),
        code: _codeController.text,
        password: _passwordController.text,
      );
      await session.startSession(result);
      navigator.popUntil((route) => route.isFirst); // AuthGate now shows the app
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                const AuthHeader(
                  icon: Icons.card_membership_outlined,
                  title: 'Join as a trainer',
                  subtitle: 'Enter the code from your invite email and choose a password.',
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: Validators.email,
                  decoration: AppTheme.input(context, label: 'Email', icon: Icons.email_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _codeController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  maxLength: 6,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.code,
                  decoration: AppTheme.input(context, label: 'Invite code', icon: Icons.pin_outlined)
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
                  label: 'Confirm password',
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  validator: (value) =>
                      value == _passwordController.text ? null : "Passwords don't match",
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _loading ? null : _submit,
                  child: _loading
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('Set password and log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
