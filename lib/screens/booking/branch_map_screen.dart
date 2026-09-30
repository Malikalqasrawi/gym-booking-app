import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../../models/branch.dart';
import '../../services/api_exception.dart';
import '../../services/booking_api.dart';
import '../../widgets/load_error.dart';
import '../../widgets/theme_toggle_button.dart';
import 'trainers_screen.dart';

/// Step 1 of booking: pick a branch on the map.
///
///   GET /api/branches → a pin for each branch → tap a pin (or a chip) → "See trainers"
class BranchMapScreen extends StatefulWidget {
  const BranchMapScreen({super.key});

  @override
  State<BranchMapScreen> createState() => _BranchMapScreenState();
}

class _BranchMapScreenState extends State<BranchMapScreen> {
  final MapController _mapController = MapController();
  late Future<List<Branch>> _branchesFuture;
  Branch? _selected;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _branchesFuture = context.read<BookingApi>().getBranches();
  }

  void _select(Branch branch) {
    setState(() => _selected = branch);
    _mapController.move(branch.position, 13.5);   // fly the map to the pin
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose a branch'),
        actions: const [ThemeToggleButton()],
      ),
      body: FutureBuilder<List<Branch>>(
        future: _branchesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            final error = snapshot.error;
            return LoadError(
              message: error is ApiException ? error.message : 'Could not load branches.',
              onRetry: () => setState(_load),
            );
          }
          final branches = snapshot.data!;
          if (branches.isEmpty) {
            return const Center(child: Text('No branches yet.'));
          }
          final selected = _selected ?? branches.first;
          return Column(
            children: [
              Expanded(child: _buildMap(branches, selected)),
              _BranchPanel(
                branches: branches,
                selected: selected,
                onSelect: _select,
                onSeeTrainers: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => TrainersScreen(branch: selected)),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMap(List<Branch> branches, Branch selected) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // OpenStreetMap tiles are light. In dark mode we pass them through a colour filter
    // that turns them into a dark grey map.
    Widget tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.malik.gym_booking',   // OSM asks every app to identify itself
    );
    if (isDark) {
      tiles = ColorFiltered(
        colorFilter: const ColorFilter.matrix(<double>[
          -0.2126, -0.7152, -0.0722, 0, 255,
          -0.2126, -0.7152, -0.0722, 0, 255,
          -0.2126, -0.7152, -0.0722, 0, 255,
          0, 0, 0, 1, 0,
        ]),
        child: tiles,
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        // Start zoomed so that EVERY branch pin fits on screen (works for 3 branches or 30)
        initialCameraFit: CameraFit.coordinates(
          coordinates: [for (final branch in branches) branch.position],
          padding: const EdgeInsets.fromLTRB(48, 72, 48, 48),
          maxZoom: 14,
        ),
      ),
      children: [
        tiles,
        MarkerLayer(
          markers: [
            for (final branch in branches)
              Marker(
                point: branch.position,
                width: 48,
                height: 48,
                alignment: Alignment.topCenter,   // the pin's tip sits exactly on the location
                child: GestureDetector(
                  onTap: () => _select(branch),
                  child: Icon(
                    Icons.location_on,
                    size: branch.id == selected.id ? 48 : 38,
                    color: branch.id == selected.id ? scheme.primary : scheme.tertiary,
                    shadows: const [Shadow(blurRadius: 6, color: Colors.black38)],
                  ),
                ),
              ),
          ],
        ),
        // OpenStreetMap's rules: always show who made the map
        RichAttributionWidget(
          attributions: [TextSourceAttribution('OpenStreetMap contributors')],
        ),
      ],
    );
  }
}

/// The panel under the map: branch chips + details of the selected branch.
class _BranchPanel extends StatelessWidget {
  const _BranchPanel({
    required this.branches,
    required this.selected,
    required this.onSelect,
    required this.onSeeTrainers,
  });

  final List<Branch> branches;
  final Branch selected;
  final ValueChanged<Branch> onSelect;
  final VoidCallback onSeeTrainers;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Material(
      color: scheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final branch = branches[i];
                    return ChoiceChip(
                      label: Text(branch.name),
                      selected: branch.id == selected.id,
                      onSelected: (_) => onSelect(branch),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Text(selected.name, style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.place_outlined, text: '${selected.address}, ${selected.city}'),
              _InfoRow(icon: Icons.schedule, text: 'Open daily ${selected.hours}'),
              if (selected.phone != null) _InfoRow(icon: Icons.phone_outlined, text: selected.phone!),
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: onSeeTrainers,
                icon: const Icon(Icons.groups_outlined),
                label: const Text('See trainers'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18, color: muted),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: muted))),
        ],
      ),
    );
  }
}
