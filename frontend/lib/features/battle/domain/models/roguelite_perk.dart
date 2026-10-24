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

  /// Catálogo completo balanceado de 8+ Perks Roguelite
  static List<RoguelitePerk> get catalog {
    return const [
      RoguelitePerk(
        id: 'pqc_shield',
        name: 'Algoritmo PQC',
        description: '+40% de blindagem pós-quântica; absorve danos críticos contra o LLM Core.',
        category: PerkCategory.defense,
        tier: 1,
        icon: Icons.shield_rounded,
      ),
      RoguelitePerk(
        id: 'cpu_overclock',
        name: 'Overclock de CPU',
        description: 'Acelera a recarga de Banda de Rede em +30% durante o combate.',
        category: PerkCategory.economy,
        tier: 2,
        icon: Icons.bolt_rounded,
      ),
      RoguelitePerk(
        id: 'laser_amplifier',
        name: 'Amplificador de Laser',
        description: 'Aumenta em +35% o dano de todos os disparos dos bastiões na grade.',
        category: PerkCategory.offense,
        tier: 1,
        icon: Icons.flash_on_rounded,
      ),
      RoguelitePerk(
        id: 'regex_deep_inspect',
        name: 'Inspeção Semântica',
        description: 'Filtra pacotes de injeção e reduz em 25% danos por exploit.',
        category: PerkCategory.aiGuard,
        tier: 3,
        icon: Icons.psychology_rounded,
      ),
      RoguelitePerk(
        id: 'honeypot_reflect',
        name: 'Honeypot Espelhado',
        description: 'Nós Honeypot e Firewalls causam +25% de dano reflexivo.',
        category: PerkCategory.defense,
        tier: 2,
        icon: Icons.bug_report_rounded,
      ),
      RoguelitePerk(
        id: 'bandwidth_cache',
        name: 'Buffer Expandido',
        description: 'Aumenta o limite máximo de Banda de Rede de 10 para 12 pontos.',
        category: PerkCategory.economy,
        tier: 1,
        icon: Icons.memory_rounded,
      ),
      RoguelitePerk(
        id: 'fast_cadence',
        name: 'Overdrive Sentinela',
        description: 'Acelera a cadência de disparo de lasers dos bastiões em +25%.',
        category: PerkCategory.offense,
        tier: 2,
        icon: Icons.speed_rounded,
      ),
      RoguelitePerk(
        id: 'sla_guardian',
        name: 'Canary de SLA',
        description: 'Restabelece +20% de SLA imediatamente e protege conexões legítimas.',
        category: PerkCategory.aiGuard,
        tier: 2,
        icon: Icons.verified_user_rounded,
      ),
    ];
  }
}
