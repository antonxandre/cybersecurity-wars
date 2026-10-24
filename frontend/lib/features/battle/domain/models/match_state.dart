import 'bastion_node.dart';
import 'game_card.dart';
import 'mainframe_model.dart';
import 'match_economy_state.dart';
import 'roguelite_perk.dart';
import 'tactical_virus_model.dart';

enum MatchPhase {
  preparation, // Fase de Build / Envio de Vírus (Legion TD) - sem tráfego inimigo
  battle,      // Batalha e colisão em tempo real nos túneis
  perkDraft,   // Pausa tática para escolha de 3 perks
  victory,     // Vitória: Mainframe oponente destruído ou todas as ondas superadas
  defeat,      // Derrota: Mainframe aliado destruído
}

/// Estado imutável da sessão da partida Multiplayer Legion TD.
class MatchState {
  final MatchPhase phase;
  final int currentWave;
  final int totalWaves;
  final double slaPercentage;
  final double coreAiIntegrity;
  final int cpuBudget;
  final double bandwidth;
  final double maxBandwidth;
  final int remainingSeconds;

  // Defesas de Grid (Campo Aliado e Campo Oponente)
  final Map<String, BastionNode> nodes;
  final Map<String, BastionNode> opponentNodes;

  // Mainframes Centrais (O 'Rei' de cada equipe)
  final MainframeModel mainframeBlue;
  final MainframeModel mainframeRed;

  // Economia Dupla (Bits e Tokens)
  final MatchEconomyState economy;

  // Fila de Vírus Táticos despachados
  final List<TacticalVirusModel> queuedVirusesForOpponent;
  final List<TacticalVirusModel> queuedVirusesFromOpponent;

  // Cartas e Perks
  final List<GameCard> hand;
  final List<GameCard> deck;
  final List<RoguelitePerk> activePerks;
  final List<RoguelitePerk> draftOptions;

  // Modificadores
  final double damageMultiplier;
  final double bandwidthRegenRate;
  final double damageReduction;

  // Estatísticas
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
    this.opponentNodes = const {},
    required this.mainframeBlue,
    required this.mainframeRed,
    required this.economy,
    this.queuedVirusesForOpponent = const [],
    this.queuedVirusesFromOpponent = const [],
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
    return MatchState(
      phase: MatchPhase.preparation,
      currentWave: 1,
      totalWaves: 3,
      slaPercentage: 100.0,
      coreAiIntegrity: 100.0,
      cpuBudget: 150,
      bandwidth: 5.0,
      maxBandwidth: 10.0,
      remainingSeconds: 35,
      nodes: {},
      opponentNodes: {},
      mainframeBlue: MainframeModel.initial(teamId: 'team_blue'),
      mainframeRed: MainframeModel.initial(teamId: 'team_red'),
      economy: MatchEconomyState.initial(),
      queuedVirusesForOpponent: [],
      queuedVirusesFromOpponent: [],
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
    Map<String, BastionNode>? opponentNodes,
    MainframeModel? mainframeBlue,
    MainframeModel? mainframeRed,
    MatchEconomyState? economy,
    List<TacticalVirusModel>? queuedVirusesForOpponent,
    List<TacticalVirusModel>? queuedVirusesFromOpponent,
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
      opponentNodes: opponentNodes ?? this.opponentNodes,
      mainframeBlue: mainframeBlue ?? this.mainframeBlue,
      mainframeRed: mainframeRed ?? this.mainframeRed,
      economy: economy ?? this.economy,
      queuedVirusesForOpponent: queuedVirusesForOpponent ?? this.queuedVirusesForOpponent,
      queuedVirusesFromOpponent: queuedVirusesFromOpponent ?? this.queuedVirusesFromOpponent,
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
