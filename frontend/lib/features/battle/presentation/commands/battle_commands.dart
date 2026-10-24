import 'package:flutter/foundation.dart';
import '../../../../core/commands/game_command.dart';
import '../../domain/models/bastion_node.dart';
import '../../domain/models/game_card.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/roguelite_perk.dart';
import '../viewmodels/battle_view_model.dart';

/// Comando para Construir Nó de Defesa na Fase de Preparação (Legion TD).
/// Suporta Rollback (Undo) completo com reembolso de CPU!
class BuildBastionNodeCommand extends GameCommand<BattleViewModel> {
  final BastionNode node;

  const BuildBastionNodeCommand(this.node);

  @override
  String get commandType => 'BUILD_NODE';

  @override
  bool get canUndo => true;

  @override
  int get resourceCost => node.cpuCost;

  @override
  bool canExecute(BattleViewModel vm) {
    final state = vm.state.value;
    // Só é permitido na fase de preparação
    if (state.phase != MatchPhase.preparation) return false;
    // Verifica orçamento de CPU
    if (state.cpuBudget < node.cpuCost) return false;
    // Verifica se a célula já está ocupada
    final key = '${node.gridX},${node.gridY}';
    return !state.nodes.containsKey(key);
  }

  @override
  Future<void> execute(BattleViewModel vm) async {
    final state = vm.state.value;
    final key = '${node.gridX},${node.gridY}';
    final updatedNodes = Map<String, BastionNode>.from(state.nodes)..[key] = node;

    vm.updateState(state.copyWith(
      cpuBudget: state.cpuBudget - node.cpuCost,
      nodes: updatedNodes,
    ));
    debugPrint('[BuildCommand] Nó construído em ($key): ${node.name}');
  }

  @override
  Future<void> undo(BattleViewModel vm) async {
    final state = vm.state.value;
    final key = '${node.gridX},${node.gridY}';
    final updatedNodes = Map<String, BastionNode>.from(state.nodes)..remove(key);

    vm.updateState(state.copyWith(
      cpuBudget: state.cpuBudget + node.cpuCost,
      nodes: updatedNodes,
    ));
    debugPrint('[BuildCommand] Desfeita construção de ($key). Reembolsados ${node.cpuCost} CPU');
  }
}

/// Comando para Desmontar Nó de Defesa na Fase de Preparação.
/// Reembolsa integralmente o custo em CPU e suporta Undo (reconstruir).
class DismantleBastionNodeCommand extends GameCommand<BattleViewModel> {
  final BastionNode node;

  const DismantleBastionNodeCommand(this.node);

  @override
  String get commandType => 'DISMANTLE_NODE';

  @override
  bool get canUndo => true;

  @override
  bool canExecute(BattleViewModel vm) {
    final state = vm.state.value;
    if (state.phase != MatchPhase.preparation) return false;
    final key = '${node.gridX},${node.gridY}';
    return state.nodes.containsKey(key);
  }

  @override
  Future<void> execute(BattleViewModel vm) async {
    final state = vm.state.value;
    final key = '${node.gridX},${node.gridY}';
    final updatedNodes = Map<String, BastionNode>.from(state.nodes)..remove(key);

    vm.updateState(state.copyWith(
      cpuBudget: state.cpuBudget + node.cpuCost,
      nodes: updatedNodes,
    ));
    debugPrint('[DismantleCommand] Nó desmontado em ($key). Reembolsados ${node.cpuCost} CPU');
  }

  @override
  Future<void> undo(BattleViewModel vm) async {
    final state = vm.state.value;
    final key = '${node.gridX},${node.gridY}';
    final updatedNodes = Map<String, BastionNode>.from(state.nodes)..[key] = node;

    vm.updateState(state.copyWith(
      cpuBudget: state.cpuBudget - node.cpuCost,
      nodes: updatedNodes,
    ));
    debugPrint('[DismantleCommand] Desfeita desmontagem de ($key). Gastos novamente ${node.cpuCost} CPU');
  }
}

/// Comando para Despachar Carta Tática na Batalha Real-Time (Clash Royale).
class DeployCardCommand extends GameCommand<BattleViewModel> {
  final GameCard card;
  final int targetLane; // 0 para Lane 1 (Uplink), 1 para Lane 2 (Downlink)

  const DeployCardCommand({required this.card, required this.targetLane});

  @override
  String get commandType => 'DEPLOY_CARD';

  @override
  int get resourceCost => card.bandwidthCost;

  @override
  bool canExecute(BattleViewModel vm) {
    final state = vm.state.value;
    if (state.phase != MatchPhase.battle) return false;
    return state.bandwidth >= card.bandwidthCost;
  }

  @override
  Future<void> execute(BattleViewModel vm) async {
    final state = vm.state.value;
    
    // Deduz energia de Banda de Rede
    final newBandwidth = state.bandwidth - card.bandwidthCost;

    // Cicla a carta da mão para o fundo do deck e compra a próxima (estilo Clash Royale)
    final updatedHand = List<GameCard>.from(state.hand)..remove(card);
    GameCard? nextCard;
    List<GameCard> updatedDeck = List<GameCard>.from(state.deck);

    if (updatedDeck.isNotEmpty) {
      nextCard = updatedDeck.removeAt(0);
      updatedHand.add(nextCard);
      updatedDeck.add(card); // Vai para o fim do deck
    } else {
      updatedHand.add(card);
    }

    vm.updateState(state.copyWith(
      bandwidth: newBandwidth,
      hand: updatedHand,
      deck: updatedDeck,
    ));

    // Notifica o motor Flame para disparar os pacotes visuais na rota escolhida
    vm.onCardDispatchedToFlame(card, targetLane);
    debugPrint('[DeployCardCommand] Carta ${card.name} despachada na Lane $targetLane');
  }
}

/// Comando para Selecionar Perk Roguelite (Archero).
class SelectPerkCommand extends GameCommand<BattleViewModel> {
  final RoguelitePerk perk;

  const SelectPerkCommand(this.perk);

  @override
  String get commandType => 'SELECT_PERK';

  @override
  bool canExecute(BattleViewModel vm) {
    return vm.state.value.phase == MatchPhase.perkDraft;
  }

  @override
  Future<void> execute(BattleViewModel vm) async {
    final state = vm.state.value;
    final updatedPerks = List<RoguelitePerk>.from(state.activePerks)..add(perk);

    // Retoma a partida para a próxima fase de batalha ou turno de preparação
    vm.updateState(state.copyWith(
      phase: MatchPhase.battle,
      activePerks: updatedPerks,
      draftOptions: [],
    ));
    debugPrint('[SelectPerkCommand] Perk selecionado: ${perk.name}');
  }
}
