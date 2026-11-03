import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Arquétipos táticos de unidades defensivas (Bastiões) na grade do PromptSec Arena
enum BastionNodeType {
  firewall, // Tanque e baixo ataque (alta durabilidade e bloqueio frontal)
  proxy,    // Ataque de curta distância (alto DPS a queima-roupa)
  vpn,      // Buff de aura em área (potencializa nós vizinhos)
  ids,      // Sniper de longo alcance (elimina alvos prioritários à distância)
  honeypot; // Controle de grupo (desaceleração e atração de malwares)

  // Compatibilidade com definições legadas
  static const BastionNodeType wafProxy = BastionNodeType.proxy;
  static const BastionNodeType vpnGateway = BastionNodeType.vpn;
  static const BastionNodeType idsSentinel = BastionNodeType.ids;
}

/// Representa um Nó Defensivo alocado na grade tática 4x4 ou protegendo o Mainframe.
/// Possui progressão de Níveis (Lv 1, Lv 2 e Lv 3) com atributos escaláveis e
/// Habilidade Especial Única desbloqueada no Nível 3.
class BastionNode {
  final String id;
  final String name;
  final BastionNodeType type;
  final int level;
  final int gridX;
  final int gridY;
  final int tokenCost;
  final double maxIntegrity;
  final double currentIntegrity;
  final double attackRange;
  final double attackDamageBits;
  final bool isDefendingMainframe;

  const BastionNode({
    required this.id,
    required this.name,
    required this.type,
    this.level = 1,
    required this.gridX,
    required this.gridY,
    required this.tokenCost,
    this.maxIntegrity = 500.0,
    this.currentIntegrity = 500.0,
    this.attackRange = 120.0,
    this.attackDamageBits = 25.0,
    this.isDefendingMainframe = false,
  });

  double get attackDamage => attackDamageBits;
  int get cpuCost => tokenCost;
  bool get isMaxLevel => level >= 3;
  bool get isSpecialUnlocked => level >= 3;

  /// Custo em Tokens para evoluir para o próximo nível
  int? get upgradeCost {
    if (level >= 3) return null;
    switch (type) {
      case BastionNodeType.firewall:
        return level == 1 ? 35 : 60;
      case BastionNodeType.proxy:
        return level == 1 ? 45 : 75;
      case BastionNodeType.vpn:
        return level == 1 ? 50 : 80;
      case BastionNodeType.ids:
        return level == 1 ? 55 : 90;
      case BastionNodeType.honeypot:
        return level == 1 ? 40 : 70;
    }
  }

  bool canUpgrade(int currentTokens) {
    final cost = upgradeCost;
    return cost != null && currentTokens >= cost;
  }

  /// Retorna uma nova instância evoluída para o próximo nível com atributos recalculados
  BastionNode upgrade() {
    if (level >= 3) return this;
    final nextLevel = level + 1;

    double newMaxHp;
    double newDps;
    double newRange;

    switch (type) {
      case BastionNodeType.firewall:
        newMaxHp = nextLevel == 2 ? 850.0 : 1400.0;
        newDps = nextLevel == 2 ? 32.0 : 50.0;
        newRange = nextLevel == 2 ? 130.0 : 145.0;
        break;
      case BastionNodeType.proxy:
        newMaxHp = nextLevel == 2 ? 550.0 : 850.0;
        newDps = nextLevel == 2 ? 80.0 : 130.0;
        newRange = nextLevel == 2 ? 125.0 : 140.0;
        break;
      case BastionNodeType.vpn:
        newMaxHp = nextLevel == 2 ? 700.0 : 1100.0;
        newDps = nextLevel == 2 ? 25.0 : 40.0;
        newRange = nextLevel == 2 ? 175.0 : 210.0;
        break;
      case BastionNodeType.ids:
        newMaxHp = nextLevel == 2 ? 460.0 : 700.0;
        newDps = nextLevel == 2 ? 110.0 : 175.0;
        newRange = nextLevel == 2 ? 230.0 : 280.0;
        break;
      case BastionNodeType.honeypot:
        newMaxHp = nextLevel == 2 ? 1050.0 : 1600.0;
        newDps = nextLevel == 2 ? 18.0 : 30.0;
        newRange = nextLevel == 2 ? 165.0 : 200.0;
        break;
    }

    final hpDifference = newMaxHp - maxIntegrity;
    final updatedCurrentHp = (currentIntegrity + hpDifference).clamp(1.0, newMaxHp);

    return copyWith(
      level: nextLevel,
      maxIntegrity: newMaxHp,
      currentIntegrity: updatedCurrentHp,
      attackDamageBits: newDps,
      attackRange: newRange,
    );
  }

  /// Descrição funcional do papel geral do nó
  String get description {
    switch (type) {
      case BastionNodeType.firewall:
        return 'Tanque de interceptação de alta durabilidade que absorve colisões na linha de frente.';
      case BastionNodeType.proxy:
        return 'Disparo concentrado a queima-roupa com altíssimo DPS contra malwares próximos.';
      case BastionNodeType.vpn:
        return 'Nó de suporte que projeta uma aura fortalecendo o poder de fogo de defesas vizinhas.';
      case BastionNodeType.ids:
        return 'Sensor tático sniper de longo alcance que prioriza ameaças com maior integridade.';
      case BastionNodeType.honeypot:
        return 'Isca neural que retarda e desvia o tráfego hostil, agrupando pacotes inimigos.';
    }
  }

  /// Efeito ativo correspondente ao nível atual da unidade
  String get currentEffectDescription {
    switch (type) {
      case BastionNodeType.firewall:
        if (level == 1) return 'Barreira Básica: Interceptação pontual e absorção pesada.';
        if (level == 2) return 'Stateful Inspection: Reduz em 15% todo dano recebido.';
        return 'Stateful Inspection (+15% de resistência passiva a dano).';

      case BastionNodeType.proxy:
        if (level == 1) return 'Alta Cadência: Disparos rápidos contra o alvo mais próximo.';
        if (level == 2) return 'Reverse Proxy: Dispara contra 2 alvos simultâneos.';
        return 'Reverse Proxy: Disparo simultâneo multithread com alta cadência.';

      case BastionNodeType.vpn:
        if (level == 1) return 'Aura Segura: Concede +15% de DPS a nós aliados no raio.';
        if (level == 2) return 'Túnel IPSec: Eleva o bônus para +25% de DPS e +15% de cadência.';
        return 'Túnel IPSec (+25% de DPS e +15% de velocidade de disparo aos vizinhos).';

      case BastionNodeType.ids:
        if (level == 1) return 'Sniper de Rede: Longo alcance focado no pacote com maior HP.';
        if (level == 2) return 'Assinatura Heurística: Causa +35% de dano bônus contra alvos pesados.';
        return 'Assinatura Heurística (+35% de dano contra malwares pesados e chefes).';

      case BastionNodeType.honeypot:
        if (level == 1) return 'Armadilha Lógica: Reduz a velocidade dos malwares no raio em 30%.';
        if (level == 2) return 'Isca Magnética: Reduz a velocidade em 45% e atrai o foco para si.';
        return 'Isca Magnética (-45% de velocidade inimiga e atração prioritária).';
    }
  }

  /// Título da Habilidade Especial desbloqueada no Nível 3
  String get specialAbilityTitle {
    switch (type) {
      case BastionNodeType.firewall:
        return 'Reflexão de Pacotes';
      case BastionNodeType.proxy:
        return 'Sobrecarga de Buffer';
      case BastionNodeType.vpn:
        return 'Malha Zero-Trust';
      case BastionNodeType.ids:
        return 'Feixe Perfurante';
      case BastionNodeType.honeypot:
        return 'Sobrecarga EMP';
    }
  }

  /// Descrição detalhada da Habilidade Especial desbloqueada no Nível 3
  String get specialAbilityDescription {
    switch (type) {
      case BastionNodeType.firewall:
        return 'Reflete 25% do dano de colisão de volta ao malware agressor.';
      case BastionNodeType.proxy:
        return 'Disparos aplicam corrosão contínua que derrete a blindagem inimiga.';
      case BastionNodeType.vpn:
        return 'Gera um escudo recarregável de 150 HP para cada nó aliado coberto pela aura.';
      case BastionNodeType.ids:
        return 'Laser perfurante atravessa a rota em linha reta, perfurando múltiplos pacotes.';
      case BastionNodeType.honeypot:
        return 'Ao cair ou ser desarmado, detona um pulso que paralisa (stun) inimigos no setor por 3s.';
    }
  }

  IconData get icon {
    switch (type) {
      case BastionNodeType.firewall:
        return Icons.shield_rounded;
      case BastionNodeType.proxy:
        return Icons.filter_alt_rounded;
      case BastionNodeType.vpn:
        return Icons.lock_outline_rounded;
      case BastionNodeType.ids:
        return Icons.radar_rounded;
      case BastionNodeType.honeypot:
        return Icons.bug_report_rounded;
    }
  }

  Color get nodeColor {
    switch (type) {
      case BastionNodeType.firewall:
        return AppColors.bastionFirewall;
      case BastionNodeType.proxy:
        return AppColors.bastionProxy;
      case BastionNodeType.vpn:
        return AppColors.bastionVpn;
      case BastionNodeType.ids:
        return AppColors.bastionIds;
      case BastionNodeType.honeypot:
        return AppColors.bastionHoneypot;
    }
  }

  /// Retorna os projetos (blueprints) de nós disponíveis para uma dada coordenada da grade
  static List<BastionNode> blueprints(int gridX, int gridY) {
    return catalog.map((template) {
      return template.copyWith(
        id: '${template.id}_${gridX}_$gridY',
        gridX: gridX,
        gridY: gridY,
      );
    }).toList();
  }

  BastionNode copyWith({
    String? id,
    String? name,
    BastionNodeType? type,
    int? level,
    int? gridX,
    int? gridY,
    int? tokenCost,
    double? maxIntegrity,
    double? currentIntegrity,
    double? attackRange,
    double? attackDamageBits,
    bool? isDefendingMainframe,
  }) {
    return BastionNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      level: level ?? this.level,
      gridX: gridX ?? this.gridX,
      gridY: gridY ?? this.gridY,
      tokenCost: tokenCost ?? this.tokenCost,
      maxIntegrity: maxIntegrity ?? this.maxIntegrity,
      currentIntegrity: currentIntegrity ?? this.currentIntegrity,
      attackRange: attackRange ?? this.attackRange,
      attackDamageBits: attackDamageBits ?? this.attackDamageBits,
      isDefendingMainframe: isDefendingMainframe ?? this.isDefendingMainframe,
    );
  }

  /// Catálogo padrão de nós disponíveis no Nível 1 para alocação na grade 4x4
  static List<BastionNode> get catalog => const [
        BastionNode(
          id: 'catalog_firewall',
          name: 'Firewall',
          type: BastionNodeType.firewall,
          level: 1,
          gridX: 0,
          gridY: 0,
          tokenCost: 40,
          maxIntegrity: 500.0,
          currentIntegrity: 500.0,
          attackRange: 120.0,
          attackDamageBits: 20.0,
        ),
        BastionNode(
          id: 'catalog_proxy',
          name: 'Proxy',
          type: BastionNodeType.proxy,
          level: 1,
          gridX: 0,
          gridY: 0,
          tokenCost: 50,
          maxIntegrity: 350.0,
          currentIntegrity: 350.0,
          attackRange: 110.0,
          attackDamageBits: 45.0,
        ),
        BastionNode(
          id: 'catalog_vpn',
          name: 'VPN',
          type: BastionNodeType.vpn,
          level: 1,
          gridX: 0,
          gridY: 0,
          tokenCost: 60,
          maxIntegrity: 450.0,
          currentIntegrity: 450.0,
          attackRange: 140.0,
          attackDamageBits: 15.0,
        ),
        BastionNode(
          id: 'catalog_ids',
          name: 'IDS',
          type: BastionNodeType.ids,
          level: 1,
          gridX: 0,
          gridY: 0,
          tokenCost: 65,
          maxIntegrity: 300.0,
          currentIntegrity: 300.0,
          attackRange: 190.0,
          attackDamageBits: 60.0,
        ),
        BastionNode(
          id: 'catalog_honeypot',
          name: 'Honeypot',
          type: BastionNodeType.honeypot,
          level: 1,
          gridX: 0,
          gridY: 0,
          tokenCost: 45,
          maxIntegrity: 650.0,
          currentIntegrity: 650.0,
          attackRange: 130.0,
          attackDamageBits: 10.0,
        ),
      ];
}
