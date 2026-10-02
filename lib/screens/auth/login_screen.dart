import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../services/auth_api.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_switch_prompt.dart';
import '../../widgets/password_field.dart';
import '../../widgets/social_sign_in_buttons.dart';
import '../../widgets/theme_toggle_button.dart';
import 'accept_invite_screen.dart';
import 'forgot_password_screen.dart';
import 'verify_email_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onSwitchToSignUp});

  final VoidCallback onSwitchToSignUp;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final session = context.read<SessionController>();
    final email = _emailController.text.trim();

    setState(() => _loading = true);
    try {
      final result = await authApi.login(email: email, password: _passwordController.text);
      await session.startSession(result); // AuthGate then shows the app
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.code == 'EMAIL_NOT_VERIFIED') {
        await _goVerify(authApi, email);
      } else {
        showError(context, e.message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// The account exists but isn't verified: send a fresh code and open the verification screen.
  Future<void> _goVerify(AuthApi authApi, String email) async {
    var info = 'Please verify your email first. We sent you a new code.';
    try {
      await authApi.resendCode(email);
    } on ApiException catch (e) {
      // A code was sent less than a minute ago and is still valid, so open the screen anyway.
      if (e.code != 'RESEND_TOO_SOON') {
        if (mounted) showError(context, e.message);
        return;
      }
      info = 'Please verify your email first. Use the code we sent you a moment ago.';
    }
    if (!mounted) return;
    showInfo(context, info);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
    );
  }

  Future<void> _openForgotPassword() async {
    final email = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => ForgotPasswordScreen(email: _emailController.text.trim())),
    );
    if (!mounted || email == null) return;
    _emailController.text = email;
    _passwordController.clear();
    showInfo(context, 'Password changed. Log in with your new password.');
  }

  void _openInvite() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => AcceptInviteScreen(email: _emailController.text.trim()),
    ));
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
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    icon: Icons.fitness_center,
                    title: 'Welcome back',
                    subtitle: 'Log in to book and manage your sessions.',
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
                  PasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (value) => Validators.required(value, 'Password'),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _loading ? null : _openForgotPassword,
                      child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 4),
                  TextButton(
                    onPressed: _loading ? null : _openInvite,
                    child: const Text('I have an invite code'),
                  ),
                  const SizedBox(height: 20),
                  const SocialSignInButtons(),
                  const SizedBox(height: 16),
                  AuthSwitchPrompt(
                    question: "Don't have an account?",
                    actionLabel: 'Sign up',
                    onPressed: widget.onSwitchToSignUp,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
