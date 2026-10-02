import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_exception.dart';
import '../../state/session_controller.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/auth_header.dart';
import '../../widgets/theme_toggle_button.dart';

/// Shown once after signing up with Google, which doesn't share phone numbers. Once saved,
/// AuthGate shows the app.
class AddPhoneScreen extends StatefulWidget {
  const AddPhoneScreen({super.key});

  @override
  State<AddPhoneScreen> createState() => _AddPhoneScreenState();
}

class _AddPhoneScreenState extends State<AddPhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<SessionController>();
    setState(() => _saving = true);
    try {
      await session.updatePhone(Validators.cleanPhone(_phoneController.text.trim()));
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstName = context.watch<SessionController>().user?.firstName ?? '';

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
                  icon: Icons.phone_outlined,
                  title: firstName.isEmpty ? 'One more thing' : 'Welcome, $firstName',
                  subtitle: 'Add your phone number so your trainer and the gym can reach you about your sessions.',
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _phoneController,
                  autofocus: true,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumber],
                  validator: Validators.phone,
                  onFieldSubmitted: (_) => _save(),
                  decoration: AppTheme.input(
                    context,
                    label: 'Phone number',
                    icon: Icons.phone_outlined,
                    hint: '+962 79 123 4567',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Continue'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _saving ? null : () => context.read<SessionController>().logout(),
                  child: const Text('Log out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
