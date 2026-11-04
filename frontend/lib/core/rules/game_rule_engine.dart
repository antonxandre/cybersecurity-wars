import '../../features/battle/domain/models/team_player_model.dart';
import 'damage_matrix.dart';

/// Motor de Regras Canônicas do Cyber Arena (CyberWars).
/// Responsável pelas regras da economia simétrica (Tokens & Bits), combate elemental,
/// resolução de vazamentos (leaks) e defesa do Mainframe Central.
class GameRuleEngine {
  GameRuleEngine._();

  // Constantes de Economia
  static const int initialTokens = 120;
  static const int initialBits = 0;
  static const int initialMiners = 1;
  static const int maxMinersPerPlayer = 12;
  static const int baseRoundIncomeTokens = 60;
  static const double baseBitRatePerSecond = 0.5;
  static const double bitRatePerMinerPerSecond = 0.4;

  // Constantes do Tabuleiro e Grade
  static const int gridColumns = 4;
  static const int gridRows = 4;

  // --- 1. Regras de Economia e Mineração ---

  /// Calcula a taxa contínua de geração de Bits por segundo com base nos mineradores ativos
  static double calculateBitMiningRate(int minersCount) {
    if (minersCount <= 0) return 0.0;
    return baseBitRatePerSecond + (minersCount * bitRatePerMinerPerSecond);
  }

  /// Calcula o custo em Tokens para recrutar um novo HashMiner Daemon
  static int calculateMinerCostTokens(int currentMinersCount) {
    return 50 + ((currentMinersCount - 1).clamp(0, maxMinersPerPlayer) * 15);
  }

  /// Verifica se o jogador pode recrutar um minerador gastando Tokens
  static bool canRecruitMiner(
      {required int currentTokens, required int currentMinersCount}) {
    if (currentMinersCount >= maxMinersPerPlayer) return false;
    final cost = calculateMinerCostTokens(currentMinersCount);
    return currentTokens >= cost;
  }

  /// Verifica se o jogador pode construir um nó na grade 4x4 gastando Tokens
  static bool canBuildNode(
      {required int currentTokens, required int nodeTokenCost}) {
    return currentTokens >= nodeTokenCost;
  }

  /// Verifica se a equipe/jogador pode enviar um malware de ataque gastando Bits
  static bool canSendOffensiveAttack(
      {required int currentBits, required int attackBitCost}) {
    return currentBits >= attackBitCost;
  }

  /// Calcula a renda total de Tokens creditada no encerramento de cada rodada
  static int calculateRoundTokensIncome({
    int baseIncome = baseRoundIncomeTokens,
    int virusIncomeBonus = 0,
  }) {
    return baseIncome + virusIncomeBonus;
  }

  // --- 2. Regras de Combate Direto ---

  /// Calcula o dano de combate direto sem multiplicadores elementais
  static double calculateDamage({
    required double baseBitsPayload,
    double extraMultiplier = 1.0,
    CombatElement? attackElement,
    CombatElement? defenseElement,
  }) {
    return baseBitsPayload * extraMultiplier;
  }

  // --- 3. Regras de Leak e Defesa do Mainframe ---

  /// Avalia se a unidade sofreu vazamento (leak = hp > 0 && isOutPlayerZone)
  static bool isUnitLeak({
    required double currentHealth,
    required bool isOutPlayerZone,
  }) {
    return currentHealth > 0 && isOutPlayerZone;
  }

  /// Retorna o quadrante do jogador adjacente para cálculo de interseção de rota
  static BoardQuadrant getAdjacentPlayerQuadrant(BoardQuadrant quadrant) {
    switch (quadrant) {
      case BoardQuadrant.topLeft:
        return BoardQuadrant.bottomLeft;
      case BoardQuadrant.bottomLeft:
        return BoardQuadrant.topLeft;
      case BoardQuadrant.topRight:
        return BoardQuadrant.bottomRight;
      case BoardQuadrant.bottomRight:
        return BoardQuadrant.topRight;
    }
  }

  /// Avalia se as unidades sobreviventes de um jogador devem se deslocar para proteger o Mainframe
  static bool shouldMoveToDefendMainframe({
    required int activeThreatsInSector,
    required bool isSectorCleared,
  }) {
    return isSectorCleared && activeThreatsInSector == 0;
  }

  /// Aplica o impacto do dano de uma ameaça vazada diretamente no Mainframe
  static double applyMainframeLeakDamage({
    required double currentMainframeHp,
    required double threatPayloadDamage,
    CombatElement? threatElement,
  }) {
    return (currentMainframeHp - threatPayloadDamage)
        .clamp(0.0, double.infinity);
  }

  /// Avalia condição de encerramento da partida
  static ({bool isGameOver, String? winnerTeam}) checkMatchOutcome({
    required double blueMainframeHp,
    required double redMainframeHp,
  }) {
    if (blueMainframeHp <= 0 && redMainframeHp <= 0) {
      return (isGameOver: true, winnerTeam: 'draw');
    }
    if (blueMainframeHp <= 0) {
      return (isGameOver: true, winnerTeam: 'team_red');
    }
    if (redMainframeHp <= 0) {
      return (isGameOver: true, winnerTeam: 'team_blue');
    }
    return (isGameOver: false, winnerTeam: null);
  }
}
