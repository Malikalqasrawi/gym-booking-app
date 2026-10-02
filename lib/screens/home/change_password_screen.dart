import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../state/session_controller.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/password_field.dart';
import '../../widgets/theme_toggle_button.dart';

/// Changes the password with the current one. Pops with true once changed; this device stays
/// logged in and the others are logged out.
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await session.changePassword(currentPassword: _currentController.text, newPassword: _newController.text);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Change password'), actions: const [ThemeToggleButton()]),
      // A Column, not a ListView: a ListView drops off-screen fields, and validate() would skip them.
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Your other devices will be logged out. This one stays logged in.',
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              PasswordField(
                controller: _currentController,
                label: 'Current password',
                validator: (value) => Validators.required(value, 'Current password'),
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _newController,
                label: 'New password',
                validator: Validators.password,
              ),
              const SizedBox(height: 14),
              PasswordField(
                controller: _confirmController,
                label: 'Confirm new password',
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _save(),
                validator: (value) => value == _newController.text ? null : "Passwords don't match",
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : const Text('Change password'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
