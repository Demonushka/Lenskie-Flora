import 'package:flutter/material.dart';

import '../models/species.dart';
import 'plant_sketch.dart';

class SpeciesThumb extends StatelessWidget {
  final Species species;
  const SpeciesThumb({super.key, required this.species});

  @override
  Widget build(BuildContext context) {
    final photo = species.photos.where((p) => p.kind == 'general').firstOrNull ?? species.photos.firstOrNull;
    if (photo == null) return PlantSketch(species: species);
    return Image.asset(
      photo.asset,
      fit: BoxFit.cover,
      cacheWidth: 600,
      errorBuilder: (_, __, ___) => PlantSketch(species: species),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final Species species;
  final bool dense;
  const StatusBadge({super.key, required this.species, this.dense = false});

  @override
  Widget build(BuildContext context) {
    final parts = [
      if (species.statusRf != null) 'КК РФ',
      if (species.statusRsya != null) 'КК РС(Я)',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: dense ? 6 : 10, vertical: dense ? 2 : 4),
      decoration: BoxDecoration(
        color: const Color(0xFFC62828),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        parts.join(' · '),
        style: TextStyle(color: Colors.white, fontSize: dense ? 11 : 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
