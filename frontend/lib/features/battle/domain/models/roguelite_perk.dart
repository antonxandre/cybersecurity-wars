import 'package:flutter/material.dart';

enum PerkCategory { defense, offense, economy, aiGuard }

/// Modelo de Perk Roguelite (estilo Archero)
class RoguelitePerk {
  final String id;
  final String name;
  final String description;
  final PerkCategory category;
  final int tier;
  final IconData icon;

  const RoguelitePerk({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.tier,
    required this.icon,
  });

  Color get categoryColor {
    switch (category) {
      case PerkCategory.defense:
        return const Color(0xFF00F0FF);
      case PerkCategory.offense:
        return const Color(0xFFFF3366);
      case PerkCategory.economy:
        return const Color(0xFFFFCC00);
      case PerkCategory.aiGuard:
        return const Color(0xFFBD00FF);
    }
  }
}
