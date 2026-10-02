import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../services/auth_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/auth_switch_prompt.dart';
import '../../widgets/password_field.dart';
import '../../widgets/social_sign_in_buttons.dart';
import '../../widgets/theme_toggle_button.dart';
import 'verify_email_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key, required this.onSwitchToLogin});

  final VoidCallback onSwitchToLogin;

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final authApi = context.read<AuthApi>();
    final email = _emailController.text.trim();

    setState(() => _loading = true);
    try {
      final message = await authApi.signUp(
        fullName: _nameController.text.trim(),
        email: email,
        phone: Validators.cleanPhone(_phoneController.text),
        password: _passwordController.text,
      );
      if (!mounted) return;

      showInfo(context, message);
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => VerifyEmailScreen(email: email)),
      );
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
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AuthHeader(
                    icon: Icons.fitness_center,
                    title: 'Create your account',
                    subtitle: 'Book sessions with the best trainers near you.',
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: Validators.fullName,
                    decoration: AppTheme.input(context, label: 'Full name', icon: Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
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
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    validator: Validators.phone,
                    decoration: AppTheme.input(
                      context,
                      label: 'Phone number',
                      icon: Icons.phone_outlined,
                      hint: '+962 79 123 4567',
                    ),
                  ),
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _passwordController,
                    label: 'Password',
                    validator: Validators.password,
                  ),
                  const SizedBox(height: 14),
                  PasswordField(
                    controller: _confirmController,
                    label: 'Confirm password',
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    validator: (value) => value != _passwordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _loading ? null : _submit,
                    child: _loading
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Sign up'),
                  ),
                  const SizedBox(height: 20),
                  const SocialSignInButtons(),
                  const SizedBox(height: 16),
                  AuthSwitchPrompt(
                    question: 'Already have an account?',
                    actionLabel: 'Log in',
                    onPressed: widget.onSwitchToLogin,
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
