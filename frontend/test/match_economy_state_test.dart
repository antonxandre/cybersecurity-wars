import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_economy_state.dart';

void main() {
  group('MatchEconomyState Refactored Economy Tests', () {
    test('Initial economy has 120 Tokens, 0 Bits, 1 HashMiner and 60 base income', () {
      final economy = MatchEconomyState.initial();
      expect(economy.tokens, equals(120));
      expect(economy.bits, equals(0));
      expect(economy.minersCount, equals(1));
      expect(economy.baseIncomeTokens, equals(60));
      expect(economy.minerCostTokens, equals(50));
    });

    test('Recruiting a HashMiner consumes Tokens and scales mining bit rate', () {
      final economy = MatchEconomyState.initial();
      expect(economy.canRecruitMiner, isTrue);

      final withTwoMiners = economy.recruitMiner();
      expect(withTwoMiners.tokens, equals(70)); // 120 - 50 = 70
      expect(withTwoMiners.minersCount, equals(2));
      expect(withTwoMiners.bitRatePerSecond, equals(1.3)); // 0.5 + 2 * 0.4
    });

    test('Spending Bits on offensive attacks increases round Token income bonus', () {
      const economy = MatchEconomyState(tokens: 100, bits: 80);
      final afterAttack = economy.registerAttackSent(bitCost: 40, incomeBonusTokens: 6);

      expect(afterAttack.bits, equals(40));
      expect(afterAttack.attackIncomeBonusTokens, equals(6));
      expect(afterAttack.totalIncomeTokens, equals(66)); // 60 + 6
    });

    test('applyRoundIncome adds total income to Tokens', () {
      const economy = MatchEconomyState(tokens: 50, bits: 20, attackIncomeBonusTokens: 10);
      final updated = economy.applyRoundIncome();

      expect(updated.tokens, equals(120)); // 50 + 60 + 10 = 120
      expect(updated.bits, equals(20));    // Bits unchanged by round token payout
    });

    test('updateBitGeneration continuously accumulates Bits over delta time', () {
      var economy = const MatchEconomyState(tokens: 50, bits: 0, minersCount: 1);
      // Taxa: 0.9 bits/segundo. Após 2 segundos => 1.8 bits (1 bit inteiro e 0.8 fracionário)
      economy = economy.updateBitGeneration(2.0);

      expect(economy.bits, equals(1));
      expect(economy.fractionalBits, closeTo(0.8, 0.01));

      // Mais 1 segundo => 0.8 + 0.9 = 1.7 => adiciona 1 bit (total 2) e sobra 0.7
      economy = economy.updateBitGeneration(1.0);
      expect(economy.bits, equals(2));
      expect(economy.fractionalBits, closeTo(0.7, 0.01));
    });
  });
}
