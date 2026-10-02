import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

/// OpenStreetMap tiles. OSM only serves light tiles, so in dark mode they are inverted into a
/// dark grey map.
class MapTiles extends StatelessWidget {
  const MapTiles({super.key});

  @override
  Widget build(BuildContext context) {
    final tiles = TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.malik.gym_booking', // required by the OSM tile usage policy
    );
    if (Theme.of(context).brightness != Brightness.dark) return tiles;
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        -0.2126, -0.7152, -0.0722, 0, 255,
        -0.2126, -0.7152, -0.0722, 0, 255,
        -0.2126, -0.7152, -0.0722, 0, 255,
        0, 0, 0, 1, 0,
      ]),
      child: tiles,
    );
  }
}

/// Attribution, required by OSM.
class MapAttribution extends StatelessWidget {
  const MapAttribution({super.key});

  @override
  Widget build(BuildContext context) {
    return RichAttributionWidget(
      attributions: [TextSourceAttribution('OpenStreetMap contributors')],
    );
  }
}
