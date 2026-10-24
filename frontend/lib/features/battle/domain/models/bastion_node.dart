import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum BastionNodeType {
  firewall,   // Bloqueia pacotes de rede simples
  honeypot,   // Isca: reflete dano e pune atacantes
  wafProxy,   // Inspeciona payloads HTTP e regex
  vpnGateway, // Criptografa tráfego legítimo
  idsSentinel // Dispara lasers rápidos contra scanners
}

/// Representa um Nó Defensivo alocado na grade de rede (estilo Legion TD).
class BastionNode {
  final String id;
  final String name;
  final BastionNodeType type;
  final int gridX;
  final int gridY;
  final int cpuCost;
  final double maxIntegrity;
  final double currentIntegrity;
  final double attackRange;
  final double attackDamage;

  const BastionNode({
    required this.id,
    required this.name,
    required this.type,
    required this.gridX,
    required this.gridY,
    required this.cpuCost,
    this.maxIntegrity = 500.0,
    this.currentIntegrity = 500.0,
    this.attackRange = 120.0,
    this.attackDamage = 25.0,
  });

  BastionNode copyWith({
    String? id,
    String? name,
    BastionNodeType? type,
    int? gridX,
    int? gridY,
    int? cpuCost,
    double? maxIntegrity,
    double? currentIntegrity,
    double? attackRange,
    double? attackDamage,
  }) {
    return BastionNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      cpuCost: cpuCost ?? this.cpuCost,
      maxIntegrity: maxIntegrity ?? this.maxIntegrity,
      currentIntegrity: currentIntegrity ?? this.currentIntegrity,
      attackRange: attackRange ?? this.attackRange,
      attackDamage: attackDamage ?? this.attackDamage,
    );
  }

  IconData get icon {
    switch (type) {
      case BastionNodeType.firewall:
        return Icons.security_rounded;
      case BastionNodeType.honeypot:
        return Icons.bug_report_rounded;
      case BastionNodeType.wafProxy:
        return Icons.filter_alt_rounded;
      case BastionNodeType.vpnGateway:
        return Icons.vpn_lock_rounded;
      case BastionNodeType.idsSentinel:
        return Icons.radar_rounded;
    }
  }

  Color get nodeColor {
    switch (type) {
      case BastionNodeType.firewall:
        return AppColors.blueTeam;
      case BastionNodeType.honeypot:
        return AppColors.cpuClock;
      case BastionNodeType.wafProxy:
        return AppColors.coreAi;
      case BastionNodeType.vpnGateway:
        return AppColors.blueTeamSecondary;
      case BastionNodeType.idsSentinel:
        return AppColors.redTeam;
    }
  }

  String get description {
    switch (type) {
      case BastionNodeType.firewall:
        return 'Alta integridade. Bloqueia pacotes de rede e força bruta.';
      case BastionNodeType.honeypot:
        return 'Isca tática. Reflete dano de volta para o tráfego inimigo.';
      case BastionNodeType.wafProxy:
        return 'Filtro semântico. Inspeciona payloads HTTP e mitiga injeções.';
      case BastionNodeType.vpnGateway:
        return 'Túnel seguro. Protege tráfego legítimo garantindo pontuação de SLA.';
      case BastionNodeType.idsSentinel:
        return 'Sentinela rápida. Dispara lasers de alta cadência contra invasores.';
    }
  }

  /// Catálogo de nós disponíveis para compra no Turno Zero
  static List<BastionNode> blueprints(int gridX, int gridY) {
    return [
      BastionNode(
        id: 'bp_firewall',
        name: 'Firewall Bastion',
        type: BastionNodeType.firewall,
        gridX: gridX,
        gridY: gridY,
        cpuCost: 50,
        maxIntegrity: 600,
        currentIntegrity: 600,
        attackRange: 100,
        attackDamage: 20,
      ),
      BastionNode(
        id: 'bp_ids',
        name: 'IDS Sentinela',
        type: BastionNodeType.idsSentinel,
        gridX: gridX,
        gridY: gridY,
        cpuCost: 65,
        maxIntegrity: 350,
        currentIntegrity: 350,
        attackRange: 140,
        attackDamage: 38,
      ),
      BastionNode(
        id: 'bp_waf',
        name: 'WAF Proxy',
        type: BastionNodeType.wafProxy,
        gridX: gridX,
        gridY: gridY,
        cpuCost: 75,
        maxIntegrity: 450,
        currentIntegrity: 450,
        attackRange: 110,
        attackDamage: 30,
      ),
      BastionNode(
        id: 'bp_honeypot',
        name: 'Honeypot Ativo',
        type: BastionNodeType.honeypot,
        gridX: gridX,
        gridY: gridY,
        cpuCost: 55,
        maxIntegrity: 500,
        currentIntegrity: 500,
        attackRange: 90,
        attackDamage: 15,
      ),
      BastionNode(
        id: 'bp_vpn',
        name: 'Gateway VPN',
        type: BastionNodeType.vpnGateway,
        gridX: gridX,
        gridY: gridY,
        cpuCost: 80,
        maxIntegrity: 400,
        currentIntegrity: 400,
        attackRange: 120,
        attackDamage: 25,
      ),
    ];
  }
}
