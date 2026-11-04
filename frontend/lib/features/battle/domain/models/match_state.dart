import 'bastion_node.dart';
import 'chat_message.dart';
import 'game_card.dart';
import 'mainframe_model.dart';
import 'match_economy_state.dart';
import 'tactical_virus_model.dart';
import 'team_player_model.dart';

enum MatchPhase {
  preparation, // Fase de Build / Envio de Vírus (Legion TD) - sem tráfego inimigo
  battle, // Batalha e colisão em tempo real nos túneis
  victory, // Vitória: Mainframe oponente destruído
  defeat, // Derrota: Mainframe aliado destruído
}

/// Estado imutável da sessão da partida Multiplayer Legion TD no Tabuleiro Top-Down.
class MatchState {
  final MatchPhase phase;
  final int currentWave;
  final int totalWaves;
  final int tokens;
  final double bandwidth;
  final double maxBandwidth;
  final int remainingSeconds;

  // Jogadores das Equipes (4 Aliados e 4 Adversários)
  final List<TeamPlayerModel> allyPlayers;
  final List<TeamPlayerModel> opponentPlayers;

  // Defesas de Grid (Campo Aliado e Campo Oponente)
  final Map<String, BastionNode> nodes;
  final Map<String, BastionNode> opponentNodes;
  final Map<BoardQuadrant, Map<String, BastionNode>> allyQuadrantNodes;

  // Mainframes Centrais (O 'Rei' de cada equipe com HP dedicado)
  final MainframeModel mainframeBlue;
  final MainframeModel mainframeRed;

  // Economia Simétrica (Tokens e Bits)
  final MatchEconomyState economy;

  // Fila de Ataques Mercenários Submetidos para o Próximo Round
  final List<TacticalVirusModel> queuedAttacksNextRound;
  final List<TacticalVirusModel> queuedVirusesForOpponent;
  final List<TacticalVirusModel> queuedVirusesFromOpponent;

  // Cartas de intervenção de rede
  final List<GameCard> hand;
  final List<GameCard> deck;

  // Modificadores
  final double damageMultiplier;
  final double bandwidthRegenRate;
  final double damageReduction;

  // Estatísticas
  final int statsPacketsNeutralized;
  final int statsDurationSeconds;
  final int totalLeaks;

  // Histórico de Mensagens do Chat Tático e Anúncios de Sistema
  final List<ChatMessage> chatMessages;

  const MatchState({
    required this.phase,
    required this.currentWave,
    required this.totalWaves,
    required this.tokens,
    required this.bandwidth,
    required this.maxBandwidth,
    required this.remainingSeconds,
    required this.allyPlayers,
    required this.opponentPlayers,
    required this.nodes,
    this.opponentNodes = const {},
    this.allyQuadrantNodes = const {
      BoardQuadrant.topLeft: {},
      BoardQuadrant.bottomLeft: {},
      BoardQuadrant.topRight: {},
      BoardQuadrant.bottomRight: {},
    },
    required this.mainframeBlue,
    required this.mainframeRed,
    required this.economy,
    this.queuedAttacksNextRound = const [],
    this.queuedVirusesForOpponent = const [],
    this.queuedVirusesFromOpponent = const [],
    required this.hand,
    required this.deck,
    this.damageMultiplier = 1.0,
    this.bandwidthRegenRate = 0.35,
    this.damageReduction = 0.0,
    this.statsPacketsNeutralized = 0,
    this.statsDurationSeconds = 0,
    this.totalLeaks = 0,
    this.chatMessages = const [],
  });

  /// Retorna os nós de um quadrante aliado específico
  Map<String, BastionNode> getNodesForQuadrant(BoardQuadrant quadrant) {
    return allyQuadrantNodes[quadrant] ?? const {};
  }

  /// Getters de compatibilidade com versões anteriores
  double get slaPercentage => mainframeBlue.hpPercentage;
  double get coreAiIntegrity => mainframeBlue.hpPercentage;
  int get cpuBudget => tokens;

  factory MatchState.initial() {
    final bluePlayers = TeamPlayerModel.initialBlueTeam();
    final redPlayers = TeamPlayerModel.initialRedTeam();

    return MatchState(
      phase: MatchPhase.preparation,
      currentWave: 1,
      totalWaves: 10,
      tokens: 120,
      bandwidth: 5.0,
      maxBandwidth: 10.0,
      remainingSeconds: 35,
      allyPlayers: bluePlayers,
      opponentPlayers: redPlayers,
      nodes: {},
      opponentNodes: {},
      allyQuadrantNodes: {
        BoardQuadrant.topLeft: {},
        BoardQuadrant.bottomLeft: {},
        BoardQuadrant.topRight: {},
        BoardQuadrant.bottomRight: {},
      },
      mainframeBlue: MainframeModel.initial(teamId: 'team_blue'),
      mainframeRed: MainframeModel.initial(teamId: 'team_red'),
      economy: MatchEconomyState.initial(),
      queuedAttacksNextRound: [],
      queuedVirusesForOpponent: [],
      queuedVirusesFromOpponent: [],
      hand: [],
      deck: [],
      damageMultiplier: 1.0,
      bandwidthRegenRate: 0.35,
      damageReduction: 0.0,
      statsPacketsNeutralized: 0,
      statsDurationSeconds: 0,
      totalLeaks: 0,
      chatMessages: [
        ChatMessage.system(
          text: 'Conexão segura estabelecida, bem-vindo à Cyber Arena!',
        ),
      ],
    );
  }

  MatchState copyWith({
    MatchPhase? phase,
    int? currentWave,
    int? totalWaves,
    int? tokens,
    double? bandwidth,
    double? maxBandwidth,
    int? remainingSeconds,
    List<TeamPlayerModel>? allyPlayers,
    List<TeamPlayerModel>? opponentPlayers,
    Map<String, BastionNode>? nodes,
    Map<String, BastionNode>? opponentNodes,
    Map<BoardQuadrant, Map<String, BastionNode>>? allyQuadrantNodes,
    MainframeModel? mainframeBlue,
    MainframeModel? mainframeRed,
    MatchEconomyState? economy,
    List<TacticalVirusModel>? queuedAttacksNextRound,
    List<TacticalVirusModel>? queuedVirusesForOpponent,
    List<TacticalVirusModel>? queuedVirusesFromOpponent,
    List<GameCard>? hand,
    List<GameCard>? deck,
    double? damageMultiplier,
    double? bandwidthRegenRate,
    double? damageReduction,
    int? statsPacketsNeutralized,
    int? statsDurationSeconds,
    int? totalLeaks,
    List<ChatMessage>? chatMessages,
  }) {
    return MatchState(
      phase: phase ?? this.phase,
      currentWave: currentWave ?? this.currentWave,
      totalWaves: totalWaves ?? this.totalWaves,
      tokens: tokens ?? this.tokens,
      bandwidth: bandwidth ?? this.bandwidth,
      maxBandwidth: maxBandwidth ?? this.maxBandwidth,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      allyPlayers: allyPlayers ?? this.allyPlayers,
      opponentPlayers: opponentPlayers ?? this.opponentPlayers,
      nodes: nodes ?? this.nodes,
      opponentNodes: opponentNodes ?? this.opponentNodes,
      allyQuadrantNodes: allyQuadrantNodes ?? this.allyQuadrantNodes,
      mainframeBlue: mainframeBlue ?? this.mainframeBlue,
      mainframeRed: mainframeRed ?? this.mainframeRed,
      economy: economy ?? this.economy,
      queuedAttacksNextRound:
          queuedAttacksNextRound ?? this.queuedAttacksNextRound,
      queuedVirusesForOpponent:
          queuedVirusesForOpponent ?? this.queuedVirusesForOpponent,
      queuedVirusesFromOpponent:
          queuedVirusesFromOpponent ?? this.queuedVirusesFromOpponent,
      hand: hand ?? this.hand,
      deck: deck ?? this.deck,
      damageMultiplier: damageMultiplier ?? this.damageMultiplier,
      bandwidthRegenRate: bandwidthRegenRate ?? this.bandwidthRegenRate,
      damageReduction: damageReduction ?? this.damageReduction,
      statsPacketsNeutralized:
          statsPacketsNeutralized ?? this.statsPacketsNeutralized,
      statsDurationSeconds: statsDurationSeconds ?? this.statsDurationSeconds,
      totalLeaks: totalLeaks ?? this.totalLeaks,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }
}
