import 'package:flutter/material.dart';

enum CardRarity { common, rare, epic, legendary }

enum CardType { exploit, patch, sentinel, payload }

/// Modelo imutável de Carta Tática (estilo Clash Royale)
class GameCard {
  final String id;
  final String name;
  final String description;
  final int bandwidthCost; // Custo de 1 a 10 de energia
  final CardRarity rarity;
  final CardType type;
  final IconData icon;
  final double basePower;

  const GameCard({
    required this.id,
    required this.name,
    required this.description,
    required this.bandwidthCost,
    required this.rarity,
    required this.type,
    required this.icon,
    this.basePower = 100.0,
  });

  Color get rarityColor {
    switch (rarity) {
      case CardRarity.common:
        return const Color(0xFF8B949E);
      case CardRarity.rare:
        return const Color(0xFF00F0FF);
      case CardRarity.epic:
        return const Color(0xFFBD00FF);
      case CardRarity.legendary:
        return const Color(0xFFFFCC00);
    }
  }
}
