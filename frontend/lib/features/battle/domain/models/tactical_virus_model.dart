import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Modelo de Vírus/Malware Tático enviado contra a equipe adversária (Mercenários no Legion TD).
/// Comprar um vírus gasta Bits (moeda minerada) e concede aumento permanente de Renda de Tokens por rodada.
class TacticalVirusModel {
  final String id;
  final String name;
  final String description;
  final int bitCost;
  final int incomeBonusTokens;
  final double packetHp;
  final double packetSpeed;
  final double attackDamageBits;
  final int unitCount;
  final IconData icon;
  final Color color;

  const TacticalVirusModel({
    required this.id,
    required this.name,
    required this.description,
    required this.bitCost,
    required this.incomeBonusTokens,
    required this.packetHp,
    required this.packetSpeed,
    required this.attackDamageBits,
    this.unitCount = 1,
    required this.icon,
    this.color = AppColors.redTeam,
  });

  int get incomeBonus => incomeBonusTokens;
  int get tokenCost => bitCost;

  /// Catálogo padrão de malwares táticos limpos e autênticos de cibersegurança
  static List<TacticalVirusModel> get catalog => const [
        TacticalVirusModel(
          id: 'virus_port_scanner',
          name: 'Port Scanner',
          description: 'Sonda rápida de reconhecimento que mapeia portas e brechas.',
          bitCost: 20,
          incomeBonusTokens: 3,
          packetHp: 40.0,
          packetSpeed: 95.0,
          attackDamageBits: 18.0,
          unitCount: 1,
          icon: Icons.radar_rounded,
          color: AppColors.bastionProxy,
        ),
        TacticalVirusModel(
          id: 'virus_syn_flood',
          name: 'SYN Flood',
          description: 'Enxame de 3 pacotes rápidos para sobrecarregar as rotas de tráfego.',
          bitCost: 40,
          incomeBonusTokens: 6,
          packetHp: 35.0,
          packetSpeed: 75.0,
          attackDamageBits: 28.0,
          unitCount: 3,
          icon: Icons.waves_rounded,
          color: AppColors.bastionFirewall,
        ),
        TacticalVirusModel(
          id: 'virus_slowloris',
          name: 'Slowloris',
          description: 'Ataque persistente com conexões lentas que consome largura de banda.',
          bitCost: 75,
          incomeBonusTokens: 12,
          packetHp: 160.0,
          packetSpeed: 45.0,
          attackDamageBits: 45.0,
          unitCount: 1,
          icon: Icons.hourglass_bottom_rounded,
          color: AppColors.bastionIds,
        ),
        TacticalVirusModel(
          id: 'virus_ransomware',
          name: 'Ransomware',
          description: 'Carga pesada blindada de impacto massivo e dano crítico ao Mainframe.',
          bitCost: 110,
          incomeBonusTokens: 18,
          packetHp: 320.0,
          packetSpeed: 35.0,
          attackDamageBits: 80.0,
          unitCount: 1,
          icon: Icons.lock_rounded,
          color: AppColors.bastionHoneypot,
        ),
      ];
}
