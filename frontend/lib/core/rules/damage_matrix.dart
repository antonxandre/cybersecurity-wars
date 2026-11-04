import 'package:flutter/material.dart';

/// Elementos da Natureza aplicados ao sistema de combate e blindagem do Cyber Arena.
enum CombatElement {
  fire, // Fogo: térmico, agressivo, sobrecarga
  water, // Água: resfriamento dinâmico, fluxo
  earth, // Terra: blindagem de silício, aterramento
  air, // Ar: radiofrequência, dispersão, rajadas rápidas
  mainframe // Núcleo central: neutro/balanceado
}

extension CombatElementExtension on CombatElement {
  String get displayName {
    switch (this) {
      case CombatElement.fire:
        return 'Fogo';
      case CombatElement.water:
        return 'Água';
      case CombatElement.earth:
        return 'Terra';
      case CombatElement.air:
        return 'Ar';
      case CombatElement.mainframe:
        return 'Mainframe Core';
    }
  }

  String get label => displayName;

  String get emoji {
    switch (this) {
      case CombatElement.fire:
        return '🔥';
      case CombatElement.water:
        return '💧';
      case CombatElement.earth:
        return '🌍';
      case CombatElement.air:
        return '💨';
      case CombatElement.mainframe:
        return '⚡';
    }
  }

  Color get color {
    switch (this) {
      case CombatElement.fire:
        return const Color(0xFFFF4500); // Laranja avermelhado
      case CombatElement.water:
        return const Color(0xFF00BFFF); // Azul profundo
      case CombatElement.earth:
        return const Color(0xFF32CD32); // Verde esmeralda / terra
      case CombatElement.air:
        return const Color(0xFFE0FFFF); // Ciano claro / ar
      case CombatElement.mainframe:
        return const Color(0xFFBD00FF); // Púrpura central
    }
  }

  IconData get icon {
    switch (this) {
      case CombatElement.fire:
        return Icons.local_fire_department_rounded;
      case CombatElement.water:
        return Icons.water_drop_rounded;
      case CombatElement.earth:
        return Icons.public_rounded;
      case CombatElement.air:
        return Icons.air_rounded;
      case CombatElement.mainframe:
        return Icons.memory_rounded;
    }
  }
}

/// Matriz Canônica de Dano Elemental (Fogo, Água, Terra, Ar).
/// Vantagem = 1.25 (125%), Neutro = 1.0 (100%), Desvantagem = 0.75 (75%).
class DamageMatrix {
  DamageMatrix._();

  static const double advantage = 1.25;
  static const double neutral = 1.00;
  static const double disadvantage = 0.75;

  /// Retorna o multiplicador de dano baseado no elemento de ataque vs elemento de blindagem
  static double getMultiplier(CombatElement attack, CombatElement defense) {
    // Mainframe Core recebe dano base neutro (100%) de todos os elementos
    if (defense == CombatElement.mainframe ||
        attack == CombatElement.mainframe) {
      return neutral;
    }

    switch (attack) {
      case CombatElement.fire:
        if (defense == CombatElement.air) return advantage; // Fogo consome Ar
        if (defense == CombatElement.water) {
          return disadvantage; // Água apaga Fogo
        }
        return neutral;

      case CombatElement.water:
        if (defense == CombatElement.fire) return advantage; // Água apaga Fogo
        if (defense == CombatElement.earth) {
          return disadvantage; // Terra absorve Água
        }
        return neutral;

      case CombatElement.earth:
        if (defense == CombatElement.water) {
          return advantage; // Terra absorve Água
        }
        if (defense == CombatElement.air) {
          return disadvantage; // Ar desgasta Terra
        }
        return neutral;

      case CombatElement.air:
        if (defense == CombatElement.earth) {
          return advantage; // Ar desgasta Terra
        }
        if (defense == CombatElement.fire) {
          return disadvantage; // Fogo queima com Ar
        }
        return neutral;

      case CombatElement.mainframe:
        return neutral;
    }
  }

  /// Calcula o dano final aplicado em Bits de carga
  static double calculateEffectiveDamage({
    required double baseAttackBits,
    required CombatElement attackElement,
    required CombatElement defenseElement,
    double extraMultiplier = 1.0,
  }) {
    final elementMultiplier = getMultiplier(attackElement, defenseElement);
    return baseAttackBits * elementMultiplier * extraMultiplier;
  }
}
