import '../models/bastion_node.dart';
import '../models/tactical_virus_model.dart';

/// Serviço de IA Scriptada para o Time Adversário (Modo 'Jogar com uma IA' / Legion TD Solo).
/// Executa rotinas estruturadas por rodada de posicionamento de defesas no Campo 2 e envio de malwares.
class ScriptedBotService {
  int _lastExecutedWave = 0;

  void reset() {
    _lastExecutedWave = 0;
  }

  /// Executa o turno de inteligência artificial para a onda atual
  ({
    Map<String, BastionNode> newOpponentNodes,
    List<TacticalVirusModel> virusesToSend,
    bool upgradeCpu,
    bool upgradeRam,
    bool upgradeDisk,
  }) executeWaveTurn(int currentWave, Map<String, BastionNode> currentOpponentNodes) {
    if (currentWave <= _lastExecutedWave) {
      return (
        newOpponentNodes: currentOpponentNodes,
        virusesToSend: [],
        upgradeCpu: false,
        upgradeRam: false,
        upgradeDisk: false,
      );
    }

    _lastExecutedWave = currentWave;
    final updatedNodes = Map<String, BastionNode>.from(currentOpponentNodes);
    final viruses = <TacticalVirusModel>[];
    bool upCpu = false;
    bool upRam = false;
    bool upDisk = false;

    final catalog = TacticalVirusModel.catalog;

    switch (currentWave) {
      case 1:
        // Onda 1: IA posiciona 2 Firewalls e envia uma sonda leve
        final fw1 = BastionNode(
          id: 'bot_fw_1_2',
          name: 'Firewall Bastion',
          type: BastionNodeType.firewall,
          gridX: 1,
          gridY: 2,
          cpuCost: 50,
        );
        final fw2 = BastionNode(
          id: 'bot_fw_2_2',
          name: 'Firewall Bastion',
          type: BastionNodeType.firewall,
          gridX: 2,
          gridY: 2,
          cpuCost: 50,
        );
        updatedNodes['${fw1.gridX},${fw1.gridY}'] = fw1;
        updatedNodes['${fw2.gridX},${fw2.gridY}'] = fw2;

        viruses.add(catalog.firstWhere((v) => v.id == 'virus_port_scanner'));
        break;

      case 2:
        // Onda 2: IA adiciona IPS Sentinel, WAF e upa a CPU do Mainframe Red
        final ips = BastionNode(
          id: 'bot_ips_1_1',
          name: 'IDS Sentinela',
          type: BastionNodeType.idsSentinel,
          gridX: 1,
          gridY: 1,
          cpuCost: 65,
        );
        final waf = BastionNode(
          id: 'bot_waf_2_3',
          name: 'WAF Proxy',
          type: BastionNodeType.wafProxy,
          gridX: 2,
          gridY: 3,
          cpuCost: 75,
        );
        updatedNodes['${ips.gridX},${ips.gridY}'] = ips;
        updatedNodes['${waf.gridX},${waf.gridY}'] = waf;

        upCpu = true;
        viruses.add(catalog.firstWhere((v) => v.id == 'virus_syn_flood'));
        break;

      case 3:
      default:
        // Onda 3: IA adiciona HoneyPot, upa RAM e Disco, e envia Trojan de alta integridade
        final hp = BastionNode(
          id: 'bot_hp_2_1',
          name: 'Honeypot Ativo',
          type: BastionNodeType.honeypot,
          gridX: 2,
          gridY: 1,
          cpuCost: 55,
        );
        updatedNodes['${hp.gridX},${hp.gridY}'] = hp;

        upRam = true;
        upDisk = true;
        viruses.add(catalog.firstWhere((v) => v.id == 'virus_trojan'));
        viruses.add(catalog.firstWhere((v) => v.id == 'virus_port_scanner'));
        break;
    }

    return (
      newOpponentNodes: updatedNodes,
      virusesToSend: viruses,
      upgradeCpu: upCpu,
      upgradeRam: upRam,
      upgradeDisk: upDisk,
    );
  }
}
