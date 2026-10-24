import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Modelo de Vírus/Malware Tático enviado contra a equipe adversária (Mercenários no Legion TD).
/// Comprar um vírus gasta Tokens e concede um aumento permanente de Renda de Bits por rodada.
class TacticalVirusModel {
  final String id;
  final String name;
  final String description;
  final int tokenCost;
  final int incomeBonus;
  final double packetHp;
  final double packetSpeed;
  final double packetDamage;
  final int unitCount;
  final IconData icon;
  final Color color;

  const TacticalVirusModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tokenCost,
    required this.incomeBonus,
    required this.packetHp,
    required this.packetSpeed,
    required this.packetDamage,
    this.unitCount = 1,
    required this.icon,
    required this.color,
  });

  /// Catálogo padrão de malwares táticos disponíveis para compra ofensiva
  static List<TacticalVirusModel> get catalog => const [
        TacticalVirusModel(
          id: 'virus_port_scanner',
          name: 'Port Scanner',
          description: 'Sonda leve e ultra-rápida. Causa pouco dano mas testa a velocidade dos firewalls.',
          tokenCost: 20,
          incomeBonus: 3,
          packetHp: 40.0,
          packetSpeed: 95.0,
          packetDamage: 15.0,
          unitCount: 1,
          icon: Icons.radar_rounded,
          color: AppColors.blueTeam,
        ),
        TacticalVirusModel(
          id: 'virus_syn_flood',
          name: 'SYN Flood',
          description: 'Enxame de 3 pacotes simultâneos projetados para sobrecarregar nós de alvo único.',
          tokenCost: 40,
          incomeBonus: 6,
          packetHp: 35.0,
          packetSpeed: 65.0,
          packetDamage: 25.0,
          unitCount: 3,
          icon: Icons.grain_rounded,
          color: AppColors.cpuClock,
        ),
        TacticalVirusModel(
          id: 'virus_trojan',
          name: 'Trojan Payload',
          description: 'Malware camuflado de alta integridade. Exige fogo concentrado para ser purgado.',
          tokenCost: 75,
          incomeBonus: 12,
          packetHp: 160.0,
          packetSpeed: 45.0,
          packetDamage: 60.0,
          unitCount: 1,
          icon: Icons.bug_report_rounded,
          color: AppColors.coreAi,
        ),
        TacticalVirusModel(
          id: 'virus_ransomware',
          name: 'Ransomware Boss',
          description: 'Ameaça devastadora de criptografia. Causa dano massivo se alcançar o Mainframe.',
          tokenCost: 140,
          incomeBonus: 24,
          packetHp: 420.0,
          packetSpeed: 30.0,
          packetDamage: 180.0,
          unitCount: 1,
          icon: Icons.lock_clock_rounded,
          color: AppColors.redTeam,
        ),
      ];
}
