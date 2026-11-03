import '../../../../core/rules/game_rule_engine.dart';

/// Estado da Economia Simétrica da Partida (Tokens & Bits).
/// - Tokens: Moeda defensiva para alocação de nós no grid 4x4 e compra de mineradores.
/// - Bits: Moeda acumulada continuamente via mineração nos mineradores para enviar ataques.
class MatchEconomyState {
  final int tokens;
  final int bits;
  final int minersCount;
  final int baseIncomeTokens;
  final int attackIncomeBonusTokens;
  final double fractionalBits;

  const MatchEconomyState({
    required this.tokens,
    required this.bits,
    this.minersCount = GameRuleEngine.initialMiners,
    this.baseIncomeTokens = GameRuleEngine.baseRoundIncomeTokens,
    this.attackIncomeBonusTokens = 0,
    this.fractionalBits = 0.0,
  });

  /// Estado inicial equilibrado para o início da Partida
  factory MatchEconomyState.initial() {
    return const MatchEconomyState(
      tokens: GameRuleEngine.initialTokens, // 120 Tokens para nós e infraestrutura
      bits: GameRuleEngine.initialBits,     // 0 Bits (gerados via mineração)
      minersCount: GameRuleEngine.initialMiners,
      baseIncomeTokens: GameRuleEngine.baseRoundIncomeTokens,
      attackIncomeBonusTokens: 0,
      fractionalBits: 0.0,
    );
  }

  /// Custo em Tokens para recrutar um novo HashMiner Daemon
  int get minerCostTokens => GameRuleEngine.calculateMinerCostTokens(minersCount);
  int get minerCost => minerCostTokens;

  /// Limite máximo de mineradores concorrentes
  int get maxMiners => GameRuleEngine.maxMinersPerPlayer;

  bool get canRecruitMiner => GameRuleEngine.canRecruitMiner(
        currentTokens: tokens,
        currentMinersCount: minersCount,
      );
  bool get canAffordMiner => canRecruitMiner;

  /// Renda permanente total de Tokens recebida no encerramento de cada rodada
  int get totalIncomeTokens => GameRuleEngine.calculateRoundTokensIncome(
        baseIncome: baseIncomeTokens,
        virusIncomeBonus: attackIncomeBonusTokens,
      );
  int get permanentIncomeTokens => totalIncomeTokens;

  /// Taxa de geração de Bits por segundo (baseada na quantidade de mineradores)
  double get bitRatePerSecond => GameRuleEngine.calculateBitMiningRate(minersCount);

  // --- Operações Econômicas ---

  MatchEconomyState spendTokens(int amount) {
    if (tokens < amount) return this;
    return copyWith(tokens: tokens - amount);
  }

  MatchEconomyState addTokens(int amount) {
    return copyWith(tokens: tokens + amount);
  }

  MatchEconomyState spendBits(int amount) {
    if (bits < amount) return this;
    return copyWith(bits: bits - amount);
  }

  MatchEconomyState addBits(int amount) {
    return copyWith(bits: bits + amount);
  }

  /// Envio de ataque ao oponente gasta Bits e aumenta a renda de Tokens por rodada!
  MatchEconomyState registerAttackSent({required int bitCost, required int incomeBonusTokens}) {
    if (bits < bitCost) return this;
    return copyWith(
      bits: bits - bitCost,
      attackIncomeBonusTokens: attackIncomeBonusTokens + incomeBonusTokens,
    );
  }

  /// Recruta um novo HashMiner gastando Tokens
  MatchEconomyState recruitMiner() {
    if (!canRecruitMiner) return this;
    return copyWith(
      tokens: tokens - minerCostTokens,
      minersCount: minersCount + 1,
    );
  }

  /// Executa o pagamento de renda de Tokens no encerramento de cada rodada de combate
  MatchEconomyState applyRoundIncome() {
    return copyWith(
      tokens: tokens + totalIncomeTokens,
    );
  }

  /// Atualização contínua de mineração de Bits durante a partida
  MatchEconomyState updateBitGeneration(double dt) {
    final added = fractionalBits + (bitRatePerSecond * dt);
    final integerBits = added.floor();
    final remainder = added - integerBits;

    if (integerBits > 0) {
      return copyWith(
        bits: bits + integerBits,
        fractionalBits: remainder,
      );
    }

    return copyWith(fractionalBits: added);
  }

  MatchEconomyState copyWith({
    int? tokens,
    int? bits,
    int? minersCount,
    int? baseIncomeTokens,
    int? attackIncomeBonusTokens,
    double? fractionalBits,
  }) {
    return MatchEconomyState(
      tokens: tokens ?? this.tokens,
      bits: bits ?? this.bits,
      minersCount: minersCount ?? this.minersCount,
      baseIncomeTokens: baseIncomeTokens ?? this.baseIncomeTokens,
      attackIncomeBonusTokens: attackIncomeBonusTokens ?? this.attackIncomeBonusTokens,
      fractionalBits: fractionalBits ?? this.fractionalBits,
    );
  }
}
