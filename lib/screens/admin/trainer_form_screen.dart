import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../models/admin_trainer.dart';
import '../../models/branch.dart';
import '../../models/training_category.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';

/// Adds a trainer (sending them an invite) or edits an existing one. Pops with the saved trainer.
class TrainerFormScreen extends StatefulWidget {
  const TrainerFormScreen({super.key, this.trainer});

  /// Null when adding a new trainer.
  final AdminTrainer? trainer;

  @override
  State<TrainerFormScreen> createState() => _TrainerFormScreenState();
}

class _TrainerFormScreenState extends State<TrainerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late Future<List<Branch>> _branches;

  late final _name = TextEditingController(text: widget.trainer?.fullName);
  late final _email = TextEditingController(text: widget.trainer?.email);
  late final _phone = TextEditingController(text: widget.trainer?.phone);
  late final _specialty = TextEditingController(text: widget.trainer?.specialty);
  late final _rate = TextEditingController(text: _number(widget.trainer?.hourlyRate));
  late final _years = TextEditingController(text: widget.trainer?.yearsOfExperience.toString());
  late final _languages = TextEditingController(text: widget.trainer?.languages);
  late final _bio = TextEditingController(text: widget.trainer?.bio);
  late final _tags = TextEditingController(text: widget.trainer?.tags.join(', '));
  late final _certifications = TextEditingController(text: widget.trainer?.certifications.join('\n'));

  late int? _branchId = widget.trainer?.branchId;
  late TrainingCategory? _category = widget.trainer?.category;
  late String? _gender = widget.trainer?.gender;
  bool _showChoiceErrors = false;
  bool _saving = false;

  bool get _isNew => widget.trainer == null;

  @override
  void initState() {
    super.initState();
    _branches = context.read<BookingApi>().getBranches();
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _email, _phone, _specialty, _rate, _years, _languages, _bio, _tags, _certifications,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  /// 25.0 -> "25", 22.5 -> "22.5"
  static String? _number(double? value) {
    if (value == null) return null;
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final choicesOk = _branchId != null && _category != null && _gender != null;
    if (!formOk || !choicesOk) {
      setState(() => _showChoiceErrors = true);
      return;
    }

    final draft = TrainerDraft(
      fullName: _name.text.trim(),
      email: _email.text.trim(),
      phone: Validators.cleanPhone(_phone.text),
      branchId: _branchId!,
      category: _category!,
      gender: _gender!,
      hourlyRate: double.parse(_rate.text.trim()),
      specialty: _specialty.text.trim(),
      bio: _bio.text.trim(),
      yearsOfExperience: int.parse(_years.text.trim()),
      languages: _languages.text.trim(),
      tags: TrainerDraft.splitTags(_tags.text),
      certifications: TrainerDraft.splitLines(_certifications.text),
    );

    final api = context.read<AdminApi>();
    final navigator = Navigator.of(context);
    setState(() => _saving = true);
    try {
      final saved = _isNew
          ? await api.createTrainer(draft)
          : await api.updateTrainer(widget.trainer!.id, draft);
      navigator.pop(saved);
    } on ApiException catch (e) {
      if (!mounted) return;
      showError(context, e.fieldErrors.isEmpty ? e.message : e.fieldErrors.values.first);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add trainer' : 'Edit trainer'),
        actions: const [ThemeToggleButton()],
      ),
      body: FutureBuilder<List<Branch>>(
        future: _branches,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return LoadError(
              message: 'Could not load the branches',
              onRetry: () => setState(() {
                _branches = context.read<BookingApi>().getBranches();
              }),
            );
          }
          return _buildForm(snapshot.data!);
        },
      ),
    );
  }

  Widget _buildForm(List<Branch> branches) {
    final text = Theme.of(context).textTheme;
    final error = Theme.of(context).colorScheme.error;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        );

    Widget choiceError(bool missing, String message) => _showChoiceErrors && missing
        ? Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(message, style: TextStyle(color: error, fontSize: 12)),
          )
        : const SizedBox.shrink();

    // A Column, not a ListView: a ListView drops off-screen fields, and validate() would skip them.
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_isNew)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  'The trainer gets an email with an invite code to set their own password.',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
            section('Account'),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              validator: Validators.fullName,
              decoration: AppTheme.input(context, label: 'Full name', icon: Icons.person_outline),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: Validators.email,
              decoration: AppTheme.input(context, label: 'Email', icon: Icons.email_outlined),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.phone,
              decoration: AppTheme.input(context, label: 'Phone', icon: Icons.phone_outlined),
            ),
            section('Branch'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final branch in branches)
                  ChoiceChip(
                    label: Text(branch.name),
                    selected: _branchId == branch.id,
                    onSelected: (_) => setState(() => _branchId = branch.id),
                  ),
              ],
            ),
            choiceError(_branchId == null, 'Pick a branch'),
            section('Training'),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final category in TrainingCategory.values)
                  ChoiceChip(
                    avatar: Icon(category.icon, size: 18),
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
              ],
            ),
            choiceError(_category == null, 'Pick a category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Male'),
                  selected: _gender == 'MALE',
                  onSelected: (_) => setState(() => _gender = 'MALE'),
                ),
                ChoiceChip(
                  label: const Text('Female'),
                  selected: _gender == 'FEMALE',
                  onSelected: (_) => setState(() => _gender = 'FEMALE'),
                ),
              ],
            ),
            choiceError(_gender == null, 'Pick a gender'),
            const SizedBox(height: 12),
            TextFormField(
              controller: _specialty,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              validator: (value) => Validators.required(value?.trim(), 'Specialty'),
              decoration: AppTheme.input(context,
                  label: 'Specialty', icon: Icons.star_outline, hint: 'e.g. Strength & conditioning'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _rate,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
                    textInputAction: TextInputAction.next,
                    validator: Validators.hourlyRate,
                    decoration: AppTheme.input(context, label: 'JOD per hour', icon: Icons.payments_outlined),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _years,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    validator: Validators.yearsOfExperience,
                    decoration: AppTheme.input(context, label: 'Years', icon: Icons.workspace_premium_outlined),
                  ),
                ),
              ],
            ),
            section('Profile'),
            TextFormField(
              controller: _languages,
              textInputAction: TextInputAction.next,
              decoration: AppTheme.input(context, label: 'Languages', icon: Icons.translate, hint: 'Arabic, English'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tags,
              textInputAction: TextInputAction.next,
              decoration: AppTheme.input(context,
                  label: 'Tags', icon: Icons.sell_outlined, hint: 'Comma-separated, e.g. Beginners, Weight loss'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _certifications,
              minLines: 2,
              maxLines: 5,
              decoration: AppTheme.input(context,
                  label: 'Certifications', icon: Icons.verified_outlined, hint: 'One per line'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _bio,
              minLines: 3,
              maxLines: 6,
              maxLength: 500,
              textCapitalization: TextCapitalization.sentences,
              decoration: AppTheme.input(context, label: 'Bio', icon: Icons.notes_outlined),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                  : Text(_isNew ? 'Add and send invite' : 'Save changes'),
            ),
          ],
        ),
      ),
    );
  }
}
