/// Estado da Economia Dupla da Partida (Bits e Tokens estilo Legion TD).
/// Gerencia os recursos defensivos, ofensivos, mineradores e a renda permanente.
class MatchEconomyState {
  final int bits;
  final int tokens;
  final int minersCount;
  final int baseIncomeBits;
  final int virusIncomeBonus;
  final double fractionalTokens;

  const MatchEconomyState({
    required this.bits,
    required this.tokens,
    this.minersCount = 1,
    this.baseIncomeBits = 60,
    this.virusIncomeBonus = 0,
    this.fractionalTokens = 0.0,
  });

  /// Estado inicial equilibrado para o início da Partida
  factory MatchEconomyState.initial() {
    return const MatchEconomyState(
      bits: 120, // Suficiente para posicionar 1 ou 2 nós básicos
      tokens: 40, // Suficiente para enviar o primeiro malware leve ou upar hardware
      minersCount: 1,
      baseIncomeBits: 60,
      virusIncomeBonus: 0,
      fractionalTokens: 0.0,
    );
  }

  /// Custo em Bits para recrutar um novo Processo Minerador de Tokens
  int get minerCostBits => 50 + ((minersCount - 1) * 15);

  /// Limite máximo de mineradores concorrentes
  int get maxMiners => 12;

  bool get canRecruitMiner => bits >= minerCostBits && minersCount < maxMiners;

  /// Renda permanente total de Bits recebida no fim de cada rodada
  int get totalIncomeBits => baseIncomeBits + virusIncomeBonus;

  /// Taxa de geração de Tokens por segundo (baseada na quantidade de mineradores)
  double get tokenRatePerSecond => 0.5 + (minersCount * 0.4);

  // --- Operações Econômicas ---

  MatchEconomyState spendBits(int amount) {
    if (bits < amount) return this;
    return copyWith(bits: bits - amount);
  }

  MatchEconomyState addBits(int amount) {
    return copyWith(bits: bits + amount);
  }

  MatchEconomyState spendTokens(int amount) {
    if (tokens < amount) return this;
    return copyWith(tokens: tokens - amount);
  }

  MatchEconomyState addTokens(int amount) {
    return copyWith(tokens: tokens + amount);
  }

  /// Envio de vírus ao oponente aumenta a renda permanente de Bits!
  MatchEconomyState registerVirusSent({required int tokenCost, required int incomeBonus}) {
    if (tokens < tokenCost) return this;
    return copyWith(
      tokens: tokens - tokenCost,
      virusIncomeBonus: virusIncomeBonus + incomeBonus,
    );
  }

  /// Recruta um novo minerador gastando Bits
  MatchEconomyState recruitMiner() {
    if (!canRecruitMiner) return this;
    return copyWith(
      bits: bits - minerCostBits,
      minersCount: minersCount + 1,
    );
  }

  /// Executa o pagamento de renda no final de cada rodada de combate
  MatchEconomyState applyRoundIncome() {
    return copyWith(
      bits: bits + totalIncomeBits,
    );
  }

  /// Atualização contínua de geração de tokens durante a partida
  MatchEconomyState updateTokenGeneration(double dt) {
    final added = fractionalTokens + (tokenRatePerSecond * dt);
    final integerTokens = added.floor();
    final remainder = added - integerTokens;

    if (integerTokens > 0) {
      return copyWith(
        tokens: tokens + integerTokens,
        fractionalTokens: remainder,
      );
    }

    return copyWith(fractionalTokens: added);
  }

  MatchEconomyState copyWith({
    int? bits,
    int? tokens,
    int? minersCount,
    int? baseIncomeBits,
    int? virusIncomeBonus,
    double? fractionalTokens,
  }) {
    return MatchEconomyState(
      bits: bits ?? this.bits,
      tokens: tokens ?? this.tokens,
      minersCount: minersCount ?? this.minersCount,
      baseIncomeBits: baseIncomeBits ?? this.baseIncomeBits,
      virusIncomeBonus: virusIncomeBonus ?? this.virusIncomeBonus,
      fractionalTokens: fractionalTokens ?? this.fractionalTokens,
    );
  }
}
