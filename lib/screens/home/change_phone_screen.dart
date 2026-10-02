import 'package:flutter/material.dart';
import 'package:phone_form_field/phone_form_field.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/api_exception.dart';
import '../../state/session_controller.dart';
import '../../utils/messages.dart';
import '../../utils/phones.dart';
import '../../widgets/phone_number_field.dart';

/// Changes the user's phone number. Pops with true once it is saved.
class ChangePhoneScreen extends StatefulWidget {
  const ChangePhoneScreen({super.key});

  @override
  State<ChangePhoneScreen> createState() => _ChangePhoneScreenState();
}

class _ChangePhoneScreenState extends State<ChangePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  late final PhoneController _phone;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _phone = Phones.controller(context.read<SessionController>().user?.phone);
  }

  @override
  void dispose() {
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final session = context.read<SessionController>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      await session.updatePhone(_phone.value.international);
      navigator.pop(true);
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMember = context.watch<SessionController>().user?.role == UserRole.member;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: const Text('Phone number')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  isMember
                      ? 'Your trainer and the gym use this number to reach you about your sessions. '
                          'A new number has to be confirmed with a code by SMS before your next booking.'
                      : 'The gym uses this number to reach you.',
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                PhoneNumberField(
                  controller: _phone,
                  autofocus: true,
                  textInputAction: TextInputAction.done,
                  onSubmitted: _save,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
