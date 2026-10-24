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

  /// Aplica dano ao LLM Core quando um pacote inimigo atinge a base
  void onCoreDamaged(double damage) {
    final current = state.value;
    if (current.phase != MatchPhase.battle) return;

    // Redução de dano concedida por perks pós-quânticos (PQC Shield)
    final effectiveDamage = (damage * (1.0 - current.damageReduction)).clamp(0.0, damage);
    final newIntegrity = (current.coreAiIntegrity - effectiveDamage).clamp(0.0, 100.0);
    debugPrint('[BattleVM] DANO NO CORE: -$effectiveDamage (Original: $damage, Redução: ${current.damageReduction * 100}%). Restante: $newIntegrity%');

    if (newIntegrity <= 0) {
      updateState(current.copyWith(
        coreAiIntegrity: 0.0,
        phase: MatchPhase.defeat,
      ));
      debugPrint('[BattleVM] DERROTA: LLM Core foi comprometido!');
    } else {
      updateState(current.copyWith(coreAiIntegrity: newIntegrity));
    }
  }

  /// Incrementa contador de pacotes invasores neutralizados pelos bastiões
  void onPacketNeutralized() {
    final current = state.value;
    updateState(current.copyWith(
      statsPacketsNeutralized: current.statsPacketsNeutralized + 1,
    ));
  }

  /// Bonifica o SLA quando tráfego legítimo HTTPS é entregue com sucesso
  void onClientDelivered() {
    final current = state.value;
    if (current.phase != MatchPhase.battle) return;

    final newSla = (current.slaPercentage + 2.0).clamp(0.0, 100.0);
    updateState(current.copyWith(slaPercentage: newSla));
  }

  /// Penaliza o SLA quando pacotes legítimos são bloqueados ou descartados
  void onSlaPenalized(double penalty) {
    final current = state.value;
    if (current.phase != MatchPhase.battle) return;

    final newSla = (current.slaPercentage - penalty).clamp(0.0, 100.0);
    debugPrint('[BattleVM] PENALIDADE DE SLA: -$penalty! SLA restante: $newSla%');

    if (newSla <= 0) {
      updateState(current.copyWith(
        slaPercentage: 0.0,
        phase: MatchPhase.defeat,
      ));
      debugPrint('[BattleVM] DERROTA: SLA de serviço chegou a 0%!');
    } else {
      updateState(current.copyWith(slaPercentage: newSla));
    }
  }

  /// Invocado quando uma onda de ataque é vencida com sucesso
  void onWaveVictory(int completedWave) {
    final current = state.value;
    if (completedWave >= current.totalWaves) {
      onMatchVictory();
    } else {
      // Avança a onda e abre o draft de perks do Archero
      final nextWave = completedWave + 1;
      final draft = _generateDraftOptions();
      updateState(current.copyWith(
        currentWave: nextWave,
        phase: MatchPhase.perkDraft,
        draftOptions: draft,
      ));
      debugPrint('[BattleVM] Onda $completedWave superada! Avançando para Onda $nextWave');
    }
  }

  /// Declara vitória definitiva da partida (todas as ondas superadas)
  void onMatchVictory() {
    final current = state.value;
    updateState(current.copyWith(phase: MatchPhase.victory));
    debugPrint('[BattleVM] VITÓRIA! Todas as ondas foram neutralizadas com sucesso!');
  }

  /// Reinicia a partida para o estado inicial
  void resetMatch() {
    executor.clearHistory();
    state.value = MatchState.initial();
    _initializeInitialDeckAndHand();
    notifyListeners();
    debugPrint('[BattleVM] Partida reiniciada.');
  }

  /// Sorteia 3 opções únicas de Perks Roguelite estilo Archero
  List<RoguelitePerk> _generateDraftOptions() {
    final catalog = List<RoguelitePerk>.from(RoguelitePerk.catalog);
    // Prioriza perks que o jogador ainda não possui
    final available = catalog
        .where((p) => !state.value.activePerks.any((active) => active.id == p.id))
        .toList();

    available.shuffle();
    if (available.length >= 3) {
      return available.take(3).toList();
    }

    catalog.shuffle();
    return catalog.take(3).toList();
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
    // Regeneração de Banda de Rede contínua (estilo Clash Royale) baseada em perks
    _bandwidthTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final current = state.value;
      if (current.phase == MatchPhase.battle && current.bandwidth < current.maxBandwidth) {
        final newBandwidth = (current.bandwidth + current.bandwidthRegenRate).clamp(0.0, current.maxBandwidth);
        updateState(current.copyWith(bandwidth: newBandwidth));
      }
    });

    // Cronômetro da partida e telemetria de duração
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.value;
      if (current.phase == MatchPhase.battle) {
        updateState(current.copyWith(
          statsDurationSeconds: current.statsDurationSeconds + 1,
        ));
      } else if (current.phase == MatchPhase.preparation && current.remainingSeconds > 0) {
        final nextSec = current.remainingSeconds - 1;
        if (nextSec <= 0) {
          startBattlePhase();
        } else {
          updateState(current.copyWith(remainingSeconds: nextSec));
        }
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
