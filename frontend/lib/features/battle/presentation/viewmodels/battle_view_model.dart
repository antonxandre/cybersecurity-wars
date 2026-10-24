import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/commands/command_executor.dart';
import '../../domain/models/bastion_node.dart';
import '../../domain/models/game_card.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/roguelite_perk.dart';
import '../commands/battle_commands.dart';

/// ViewModel que orquestra a sessão de jogo e a ponte entre a UI e o Flame Engine.
class BattleViewModel extends ChangeNotifier {
  late final CommandExecutor<BattleViewModel> executor;
  final ValueNotifier<MatchState> state = ValueNotifier(MatchState.initial());

  Timer? _bandwidthTimer;
  Timer? _countdownTimer;

  // Stream de eventos despachados para o Flame Game Canvas
  final StreamController<({GameCard card, int lane})> _flameDispatches =
      StreamController.broadcast();
  Stream<({GameCard card, int lane})> get flameDispatches => _flameDispatches.stream;

  BattleViewModel() {
    executor = CommandExecutor(this);
    _initializeInitialDeckAndHand();
    _startTimers();
  }

  void updateState(MatchState newState) {
    state.value = newState;
    notifyListeners();
  }

  /// Notifica o Flame Engine sobre cartas jogadas nas rotas de rede
  void onCardDispatchedToFlame(GameCard card, int lane) {
    _flameDispatches.add((card: card, lane: lane));
  }

  /// Constrói um nó no grid (Turno de Preparação / Legion TD)
  Future<bool> buildNode(BastionNode node) async {
    return executor.run(BuildBastionNodeCommand(node));
  }

  /// Desfaz a última alocação de nó com reembolso de CPU
  Future<bool> undoBuild() async {
    return executor.undoLast();
  }

  /// Desmonta um nó específico no grid e reembolsa seu custo de CPU
  Future<bool> dismantleNode(BastionNode node) async {
    return executor.run(DismantleBastionNodeCommand(node));
  }

  /// Despacha uma carta na rota selecionada (Clash Royale)
  Future<bool> deployCard(GameCard card, int targetLane) async {
    return executor.run(DeployCardCommand(card: card, targetLane: targetLane));
  }

  /// Seleciona um perk de aprimoramento (Archero)
  Future<bool> selectPerk(RoguelitePerk perk) async {
    return executor.run(SelectPerkCommand(perk));
  }

  /// Inicia a fase de combate em tempo real
  void startBattlePhase() {
    executor.clearHistory();
    updateState(state.value.copyWith(
      phase: MatchPhase.battle,
      remainingSeconds: 60,
    ));
  }

  /// Dispara a seleção de Perks Roguelite estilo Archero
  void triggerPerkDraft() {
    final draft = _generateDraftOptions();
    updateState(state.value.copyWith(
      phase: MatchPhase.perkDraft,
      draftOptions: draft,
    ));
  }

  List<RoguelitePerk> _generateDraftOptions() {
    return const [
      RoguelitePerk(
        id: 'pqc_shield',
        name: 'Algoritmo PQC',
        description: '+40% de blindagem criptográfica quântica contra quebra de chaves.',
        category: PerkCategory.defense,
        tier: 1,
        icon: Icons.shield_rounded,
      ),
      RoguelitePerk(
        id: 'cpu_overclock',
        name: 'Overclock de CPU',
        description: 'Recupera Banda de Rede 25% mais rápido durante o combate.',
        category: PerkCategory.economy,
        tier: 2,
        icon: Icons.bolt_rounded,
      ),
      RoguelitePerk(
        id: 'regex_deep_inspect',
        name: 'Inspeção Semântica',
        description: 'Neutraliza o primeiro payload de Prompt Injection recebido pela IA.',
        category: PerkCategory.aiGuard,
        tier: 3,
        icon: Icons.psychology_rounded,
      ),
    ];
  }

  void _initializeInitialDeckAndHand() {
    final pool = [
      const GameCard(
        id: 'syn_flood',
        name: 'SYN Flooder',
        description: 'Envia enxame de pacotes leves para sobrecarregar buffers.',
        bandwidthCost: 3,
        rarity: CardRarity.common,
        type: CardType.exploit,
        icon: Icons.waves_rounded,
        basePower: 80,
      ),
      const GameCard(
        id: 'nmap_scan',
        name: 'Port Recon',
        description: 'Varre portas abertas e revela vulnerabilidades nos bastiões.',
        bandwidthCost: 2,
        rarity: CardRarity.common,
        type: CardType.exploit,
        icon: Icons.radar_rounded,
        basePower: 40,
      ),
      const GameCard(
        id: 'emergency_patch',
        name: 'Hot-Patch',
        description: 'Injeta regra emergencial restaurando 200 de integridade a um bastião.',
        bandwidthCost: 4,
        rarity: CardRarity.rare,
        type: CardType.patch,
        icon: Icons.build_circle_rounded,
        basePower: 200,
      ),
      const GameCard(
        id: 'jailbreak_payload',
        name: 'Jailbreak DAN',
        description: 'Payload avançado focado em atingir o LLM Core do adversário.',
        bandwidthCost: 6,
        rarity: CardRarity.legendary,
        type: CardType.payload,
        icon: Icons.terminal_rounded,
        basePower: 350,
      ),
      const GameCard(
        id: 'vpn_sentinel',
        name: 'Túnel WireGuard',
        description: 'Encapsula pacotes em canal seguro com imunidade a interceptação.',
        bandwidthCost: 5,
        rarity: CardRarity.epic,
        type: CardType.sentinel,
        icon: Icons.lock_outline_rounded,
        basePower: 250,
      ),
    ];

    updateState(state.value.copyWith(
      hand: pool.take(4).toList(),
      deck: pool.skip(4).toList(),
    ));
  }

  void _startTimers() {
    // Regeneração de Banda de Rede contínua (estilo Clash Royale)
    _bandwidthTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final current = state.value;
      if (current.phase == MatchPhase.battle && current.bandwidth < current.maxBandwidth) {
        final newBandwidth = (current.bandwidth + 0.35).clamp(0.0, current.maxBandwidth);
        updateState(current.copyWith(bandwidth: newBandwidth));
      }
    });

    // Cronômetro da partida
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.value;
      if (current.remainingSeconds > 0) {
        updateState(current.copyWith(remainingSeconds: current.remainingSeconds - 1));
      } else if (current.phase == MatchPhase.preparation) {
        startBattlePhase();
      } else if (current.phase == MatchPhase.battle) {
        triggerPerkDraft();
      }
    });
  }

  @override
  void dispose() {
    _bandwidthTimer?.cancel();
    _countdownTimer?.cancel();
    _flameDispatches.close();
    super.dispose();
  }
}
