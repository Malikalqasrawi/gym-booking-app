import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../services/admin_api.dart';
import '../../services/api_exception.dart';
import '../../theme/app_theme.dart';
import '../../utils/messages.dart';
import '../../utils/validators.dart';
import '../../widgets/map_tiles.dart';
import '../../widgets/theme_toggle_button.dart';

/// Adds a branch or edits one, with its location picked on the map. Pops with a message for the
/// list once something was saved or deleted.
class BranchFormScreen extends StatefulWidget {
  const BranchFormScreen({super.key, this.branch});

  /// Null when adding a new branch.
  final Branch? branch;

  @override
  State<BranchFormScreen> createState() => _BranchFormScreenState();
}

class _BranchFormScreenState extends State<BranchFormScreen> {
  /// Central Amman, where a new branch's pin starts.
  static const _amman = LatLng(31.9539, 35.9106);

  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.branch?.name);
  late final _address = TextEditingController(text: widget.branch?.address);
  late final _city = TextEditingController(text: widget.branch?.city ?? 'Amman');
  late final _phone = TextEditingController(text: widget.branch?.phone);
  late TimeOfDay _opening = _parse(widget.branch?.openingTime ?? '06:00');
  late TimeOfDay _closing = _parse(widget.branch?.closingTime ?? '23:00');
  late LatLng _position = widget.branch?.position ?? _amman;
  bool _busy = false;

  bool get _isNew => widget.branch == null;

  @override
  void dispose() {
    for (final controller in [_name, _address, _city, _phone]) {
      controller.dispose();
    }
    super.dispose();
  }

  static TimeOfDay _parse(String hhmm) {
    final parts = hhmm.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  static String _format(TimeOfDay time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

  /// Required, at most [max] characters. Messages match the backend's.
  static String? Function(String?) _text(String field, int max) => (value) {
        final text = value?.trim() ?? '';
        if (text.isEmpty) return '$field is required';
        if (text.length > max) return '$field is too long';
        return null;
      };

  Future<void> _pickTime({required bool opening}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: opening ? _opening : _closing,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (opening) {
        _opening = picked;
      } else {
        _closing = picked;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_format(_closing).compareTo(_format(_opening)) <= 0) {
      showError(context, 'Closing time must be after opening time');
      return;
    }
    final draft = BranchDraft(
      name: _name.text,
      address: _address.text,
      city: _city.text,
      position: _position,
      phone: Validators.cleanPhone(_phone.text),
      openingTime: _format(_opening),
      closingTime: _format(_closing),
    );

    final api = context.read<AdminApi>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      if (_isNew) {
        final created = await api.createBranch(draft);
        navigator.pop('${created.name} added.');
      } else {
        await api.updateBranch(widget.branch!.id, draft);
        navigator.pop('Saved.');
      }
    } on ApiException catch (e) {
      if (mounted) showError(context, e.fieldErrors.isEmpty ? e.message : e.fieldErrors.values.first);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    final branch = widget.branch!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${branch.name}?'),
        content: const Text('This can\'t be undone. A branch that has trainers or bookings can\'t be deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Back')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 44), // not full-width inside a dialog
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final api = context.read<AdminApi>();
    final navigator = Navigator.of(context);
    setState(() => _busy = true);
    try {
      await api.deleteBranch(branch.id);
      navigator.pop('${branch.name} deleted.');
    } on ApiException catch (e) {
      if (mounted) showError(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = TextStyle(color: scheme.onSurfaceVariant);

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title, style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Add branch' : 'Edit branch'),
        actions: const [ThemeToggleButton()],
      ),
      // A Column, not a ListView: a ListView drops off-screen fields, and validate() would skip them.
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _text('Name', 100),
                decoration: AppTheme.input(context, label: 'Name', icon: Icons.store_mall_directory_outlined,
                    hint: 'e.g. Abdoun Branch'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _address,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: _text('Address', 200),
                decoration: AppTheme.input(context, label: 'Address', icon: Icons.place_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _city,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _text('City', 60),
                decoration: AppTheme.input(context, label: 'City', icon: Icons.location_city_outlined),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                validator: (value) => (value == null || value.trim().isEmpty) ? null : Validators.phone(value),
                decoration: AppTheme.input(context, label: 'Phone (optional)', icon: Icons.phone_outlined),
              ),
              section('Opening hours'),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(opening: true),
                      icon: const Icon(Icons.wb_sunny_outlined),
                      label: Text('Opens ${_format(_opening)}'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(opening: false),
                      icon: const Icon(Icons.nightlight_outlined),
                      label: Text('Closes ${_format(_closing)}'),
                    ),
                  ),
                ],
              ),
              section('Location'),
              Text('Tap the map to move the pin to the branch\'s entrance.', style: muted),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 280,
                  child: FlutterMap(
                    options: MapOptions(
                      initialCenter: _position,
                      initialZoom: 15,
                      onTap: (_, point) => setState(() => _position = point),
                    ),
                    children: [
                      const MapTiles(),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _position,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter, // puts the pin's tip on the location
                            child: Icon(
                              Icons.location_on,
                              size: 48,
                              color: scheme.primary,
                              shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
                            ),
                          ),
                        ],
                      ),
                      const MapAttribution(),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_position.latitude.toStringAsFixed(5)}, ${_position.longitude.toStringAsFixed(5)}',
                style: muted.copyWith(fontSize: 12),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _busy ? null : _save,
                child: _busy
                    ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.5))
                    : Text(_isNew ? 'Add branch' : 'Save changes'),
              ),
              if (!_isNew) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _delete,
                  style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete branch'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
