import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/rules/game_rule_engine.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/bastion_node.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/team_player_model.dart';

void main() {
  group('Combat & Unit Level Progression Tests', () {
    test('calculateDamage computes direct combat without elemental weakness', () {
      final directDmg = GameRuleEngine.calculateDamage(baseBitsPayload: 40.0);
      expect(directDmg, equals(40.0));

      final boostedDmg = GameRuleEngine.calculateDamage(baseBitsPayload: 40.0, extraMultiplier: 1.5);
      expect(boostedDmg, equals(60.0));
    });

    test('BastionNode upgrades accurately scale stats across levels 1, 2, 3', () {
      final fwLv1 = BastionNode.catalog.firstWhere((n) => n.type == BastionNodeType.firewall);
      expect(fwLv1.level, equals(1));
      expect(fwLv1.maxIntegrity, equals(500.0));
      expect(fwLv1.attackDamage, equals(20.0));
      expect(fwLv1.attackRange, equals(120.0));
      expect(fwLv1.upgradeCost, equals(35));
      expect(fwLv1.isSpecialUnlocked, isFalse);

      final fwLv2 = fwLv1.upgrade();
      expect(fwLv2.level, equals(2));
      expect(fwLv2.maxIntegrity, equals(850.0));
      expect(fwLv2.attackDamage, equals(32.0));
      expect(fwLv2.attackRange, equals(130.0));
      expect(fwLv2.upgradeCost, equals(60));
      expect(fwLv2.isSpecialUnlocked, isFalse);

      final fwLv3 = fwLv2.upgrade();
      expect(fwLv3.level, equals(3));
      expect(fwLv3.maxIntegrity, equals(1400.0));
      expect(fwLv3.attackDamage, equals(50.0));
      expect(fwLv3.attackRange, equals(145.0));
      expect(fwLv3.upgradeCost, isNull);
      expect(fwLv3.isSpecialUnlocked, isTrue);
      expect(fwLv3.specialAbilityTitle, equals('Reflexão de Pacotes'));
    });
  });

  group('GameRuleEngine Economy & Lifecycle Tests', () {
    test('Mining rate scales properly with miner count', () {
      expect(GameRuleEngine.calculateBitMiningRate(1), equals(0.9)); // 0.5 + 0.4
      expect(GameRuleEngine.calculateBitMiningRate(2), equals(1.3)); // 0.5 + 0.8
      expect(GameRuleEngine.calculateBitMiningRate(5), equals(2.5)); // 0.5 + 2.0
    });

    test('Miner recruitment cost scales linearly and stops at max limit', () {
      expect(GameRuleEngine.calculateMinerCostTokens(1), equals(50));
      expect(GameRuleEngine.calculateMinerCostTokens(2), equals(65));
      expect(GameRuleEngine.calculateMinerCostTokens(3), equals(80));

      expect(GameRuleEngine.canRecruitMiner(currentTokens: 49, currentMinersCount: 1), isFalse);
      expect(GameRuleEngine.canRecruitMiner(currentTokens: 50, currentMinersCount: 1), isTrue);
      expect(GameRuleEngine.canRecruitMiner(currentTokens: 500, currentMinersCount: 12), isFalse);
    });

    test('Building node validation requires sufficient Tokens', () {
      expect(GameRuleEngine.canBuildNode(currentTokens: 100, nodeTokenCost: 80), isTrue);
      expect(GameRuleEngine.canBuildNode(currentTokens: 70, nodeTokenCost: 80), isFalse);
    });

    test('Offensive attack dispatch validation requires sufficient Bits', () {
      expect(GameRuleEngine.canSendOffensiveAttack(currentBits: 40, attackBitCost: 35), isTrue);
      expect(GameRuleEngine.canSendOffensiveAttack(currentBits: 20, attackBitCost: 35), isFalse);
    });

    test('Mainframe leak damage applies directly to Mainframe HP', () {
      final remainingHp = GameRuleEngine.applyMainframeLeakDamage(
        currentMainframeHp: 1000.0,
        threatPayloadDamage: 50.0,
      );
      expect(remainingHp, equals(950.0));
    });

    test('isUnitLeak evaluates hp > 0 and isOutPlayerZone accurately', () {
      expect(GameRuleEngine.isUnitLeak(currentHealth: 50.0, isOutPlayerZone: true), isTrue);
      expect(GameRuleEngine.isUnitLeak(currentHealth: 0.0, isOutPlayerZone: true), isFalse);
      expect(GameRuleEngine.isUnitLeak(currentHealth: -10.0, isOutPlayerZone: true), isFalse);
      expect(GameRuleEngine.isUnitLeak(currentHealth: 50.0, isOutPlayerZone: false), isFalse);
    });

    test('getAdjacentPlayerQuadrant returns paired adjacent player quadrant', () {
      expect(GameRuleEngine.getAdjacentPlayerQuadrant(BoardQuadrant.topLeft), equals(BoardQuadrant.bottomLeft));
      expect(GameRuleEngine.getAdjacentPlayerQuadrant(BoardQuadrant.bottomLeft), equals(BoardQuadrant.topLeft));
      expect(GameRuleEngine.getAdjacentPlayerQuadrant(BoardQuadrant.topRight), equals(BoardQuadrant.bottomRight));
      expect(GameRuleEngine.getAdjacentPlayerQuadrant(BoardQuadrant.bottomRight), equals(BoardQuadrant.topRight));
    });

    test('Match outcome triggers victory when one Mainframe is destroyed', () {
      expect(
        GameRuleEngine.checkMatchOutcome(blueMainframeHp: 1000.0, redMainframeHp: 1000.0).isGameOver,
        isFalse,
      );

      final redLoss = GameRuleEngine.checkMatchOutcome(blueMainframeHp: 500.0, redMainframeHp: 0.0);
      expect(redLoss.isGameOver, isTrue);
      expect(redLoss.winnerTeam, equals('team_blue'));

      final blueLoss = GameRuleEngine.checkMatchOutcome(blueMainframeHp: 0.0, redMainframeHp: 800.0);
      expect(blueLoss.isGameOver, isTrue);
      expect(blueLoss.winnerTeam, equals('team_red'));
    });
  });
}
