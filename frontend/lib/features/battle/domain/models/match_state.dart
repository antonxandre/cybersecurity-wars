import 'bastion_node.dart';
import 'game_card.dart';
import 'roguelite_perk.dart';

enum MatchPhase {
  preparation, // Fase de Build (Legion TD) - sem tráfego inimigo
  battle,      // Batalha Real-Time em 2 lanes (Clash Royale)
  perkDraft,   // Pausa tática para escolha de 3 perks (Archero)
  victory,
  defeat,
}

/// Estado imutável da sessão da partida.
class MatchState {
  final MatchPhase phase;
  final int currentWave;
  final int totalWaves;
  final double slaPercentage;       // SLA de serviço (derrota se zerar)
  final double coreAiIntegrity;     // Vida do LLM Core (derrota se zerar)
  final int cpuBudget;              // Moeda de construção no grid
  final double bandwidth;           // Energia/Mana de combate em tempo real (0.0 a 10.0)
  final double maxBandwidth;
  final int remainingSeconds;
  final Map<String, BastionNode> nodes;
  final List<GameCard> hand;
  final List<GameCard> deck;
  final List<RoguelitePerk> activePerks;
  final List<RoguelitePerk> draftOptions;

  // Modificadores dinâmicos providos pelos Perks do Archero
  final double damageMultiplier;
  final double bandwidthRegenRate;
  final double damageReduction;

  // Estatísticas da partida para o relatório final
  final int statsPacketsNeutralized;
  final int statsDurationSeconds;

  const MatchState({
    required this.phase,
    required this.currentWave,
    required this.totalWaves,
    required this.slaPercentage,
    required this.coreAiIntegrity,
    required this.cpuBudget,
    required this.bandwidth,
    required this.maxBandwidth,
    required this.remainingSeconds,
    required this.nodes,
    required this.hand,
    required this.deck,
    required this.activePerks,
    this.draftOptions = const [],
    this.damageMultiplier = 1.0,
    this.bandwidthRegenRate = 0.35,
    this.damageReduction = 0.0,
    this.statsPacketsNeutralized = 0,
    this.statsDurationSeconds = 0,
  });

  factory MatchState.initial() {
    return const MatchState(
      phase: MatchPhase.preparation,
      currentWave: 1,
      totalWaves: 3,
      slaPercentage: 100.0,
      coreAiIntegrity: 100.0,
      cpuBudget: 150,
      bandwidth: 5.0,
      maxBandwidth: 10.0,
      remainingSeconds: 25,
      nodes: {},
      hand: [],
      deck: [],
      activePerks: [],
      draftOptions: [],
      damageMultiplier: 1.0,
      bandwidthRegenRate: 0.35,
      damageReduction: 0.0,
      statsPacketsNeutralized: 0,
      statsDurationSeconds: 0,
    );
  }

  MatchState copyWith({
    MatchPhase? phase,
    int? currentWave,
    int? totalWaves,
    double? slaPercentage,
    double? coreAiIntegrity,
    int? cpuBudget,
    double? bandwidth,
    double? maxBandwidth,
    int? remainingSeconds,
    Map<String, BastionNode>? nodes,
    List<GameCard>? hand,
    List<GameCard>? deck,
    List<RoguelitePerk>? activePerks,
    List<RoguelitePerk>? draftOptions,
    double? damageMultiplier,
    double? bandwidthRegenRate,
    double? damageReduction,
    int? statsPacketsNeutralized,
    int? statsDurationSeconds,
  }) {
    return MatchState(
      phase: phase ?? this.phase,
      currentWave: currentWave ?? this.currentWave,
      totalWaves: totalWaves ?? this.totalWaves,
      slaPercentage: slaPercentage ?? this.slaPercentage,
      coreAiIntegrity: coreAiIntegrity ?? this.coreAiIntegrity,
      cpuBudget: cpuBudget ?? this.cpuBudget,
      bandwidth: bandwidth ?? this.bandwidth,
      maxBandwidth: maxBandwidth ?? this.maxBandwidth,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      nodes: nodes ?? this.nodes,
      hand: hand ?? this.hand,
      deck: deck ?? this.deck,
      activePerks: activePerks ?? this.activePerks,
      draftOptions: draftOptions ?? this.draftOptions,
      damageMultiplier: damageMultiplier ?? this.damageMultiplier,
      bandwidthRegenRate: bandwidthRegenRate ?? this.bandwidthRegenRate,
      damageReduction: damageReduction ?? this.damageReduction,
      statsPacketsNeutralized: statsPacketsNeutralized ?? this.statsPacketsNeutralized,
      statsDurationSeconds: statsDurationSeconds ?? this.statsDurationSeconds,
    );
  }
}
