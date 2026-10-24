import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Modelo de Domínio do Mainframe Central (O 'Rei' no Legion TD Cyber).
/// Entidade máxima de sobrevivência de cada equipe, protegida pelos Bastiões de Defesa.
class MainframeModel {
  final String teamId;
  final double currentHp;
  final int cpuLevel;
  final int ramLevel;
  final int diskLevel;

  const MainframeModel({
    required this.teamId,
    required this.currentHp,
    this.cpuLevel = 1,
    this.ramLevel = 1,
    this.diskLevel = 1,
  });

  /// Fábrica inicial com valores padrão calibrados para a primeira rodada
  factory MainframeModel.initial({required String teamId}) {
    const baseHp = 1000.0;
    return MainframeModel(
      teamId: teamId,
      currentHp: baseHp,
      cpuLevel: 1,
      ramLevel: 1,
      diskLevel: 1,
    );
  }

  // --- Atributos Derivados de Hardware ---

  /// Capacidade total de armazenamento de dados / HP Máximo do Mainframe
  double get maxHp => 1000.0 + ((diskLevel - 1) * 400.0);

  /// Dano por segundo (DPS) de feixe laser defensivo disparado contra ameaças
  double get laserDps => 50.0 + ((cpuLevel - 1) * 30.0);

  /// Número de alvos simultâneos que o Mainframe pode alvejar (Canais de buffer de RAM)
  int get targetCount => ramLevel.clamp(1, 4);

  /// Alcance do feixe defensivo na sala do servidor
  double get defenseRange => 260.0;

  /// Percentual de integridade restante (0 a 100)
  double get hpPercentage => (currentHp / maxHp * 100.0).clamp(0.0, 100.0);

  /// Indica se o Mainframe foi comprometido / destruído
  bool get isDestroyed => currentHp <= 0.0;

  // --- Custos de Upgrade de Hardware (em Tokens) ---

  int get upgradeCostCpu => 35 + (cpuLevel * 25);
  int get upgradeCostRam => 50 + (ramLevel * 45);
  int get upgradeCostDisk => 30 + (diskLevel * 20);

  bool get canUpgradeCpu => cpuLevel < 10;
  bool get canUpgradeRam => ramLevel < 4;
  bool get canUpgradeDisk => diskLevel < 10;

  Color get teamColor => teamId.contains('blue') ? AppColors.blueTeam : AppColors.redTeam;

  // --- Métodos de Evolução e Combate ---

  MainframeModel upgradeCpu() {
    if (!canUpgradeCpu) return this;
    return copyWith(cpuLevel: cpuLevel + 1);
  }

  MainframeModel upgradeRam() {
    if (!canUpgradeRam) return this;
    return copyWith(ramLevel: ramLevel + 1);
  }

  MainframeModel upgradeDisk() {
    if (!canUpgradeDisk) return this;
    final newDisk = diskLevel + 1;
    final addedHp = 400.0;
    return copyWith(
      diskLevel: newDisk,
      currentHp: (currentHp + addedHp).clamp(0.0, 1000.0 + ((newDisk - 1) * 400.0)),
    );
  }

  MainframeModel receiveDamage(double damage) {
    final nextHp = (currentHp - damage).clamp(0.0, maxHp);
    return copyWith(currentHp: nextHp);
  }

  MainframeModel heal(double amount) {
    final nextHp = (currentHp + amount).clamp(0.0, maxHp);
    return copyWith(currentHp: nextHp);
  }

  MainframeModel copyWith({
    String? teamId,
    double? currentHp,
    int? cpuLevel,
    int? ramLevel,
    int? diskLevel,
  }) {
    return MainframeModel(
      teamId: teamId ?? this.teamId,
      currentHp: currentHp ?? this.currentHp,
      cpuLevel: cpuLevel ?? this.cpuLevel,
      ramLevel: ramLevel ?? this.ramLevel,
      diskLevel: diskLevel ?? this.diskLevel,
    );
  }
}
