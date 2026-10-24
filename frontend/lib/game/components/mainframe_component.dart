import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../features/battle/domain/models/mainframe_model.dart';
import 'data_packet_component.dart';
import 'laser_beam_effect.dart';

/// Componente visual do Mainframe Central (O 'Rei' no Legion TD Cyber).
/// Renderiza o rack de servidores com refrigeração líquida neon e defende a base
/// com múltiplos feixes de laser simultâneos (de acordo com o ramLevel).
class MainframeComponent extends PositionComponent {
  final String teamId;
  final MainframeModel Function() getModel;
  final List<DataPacketComponent> Function() getEnemyPackets;
  final void Function(double damage)? onDamaged;

  double _ledTimer = 0.0;
  double _pulseTimer = 0.0;
  double _attackCooldown = 0.0;

  MainframeComponent({
    required this.teamId,
    required this.getModel,
    required this.getEnemyPackets,
    this.onDamaged,
    required Vector2 position,
    Vector2? size,
  }) : super(
          position: position,
          size: size ?? Vector2(130, 90),
          anchor: Anchor.center,
          priority: 5,
        );

  MainframeModel get model => getModel();
  bool get isBlue => teamId.contains('blue');
  Color get themeColor => isBlue ? AppColors.blueTeam : AppColors.redTeam;

  @override
  void update(double dt) {
    super.update(dt);
    _ledTimer = (_ledTimer + dt * 4.0) % (math.pi * 2);
    _pulseTimer = (_pulseTimer + dt * 2.5) % (math.pi * 2);
    _attackCooldown = math.max(0.0, _attackCooldown - dt);

    if (model.isDestroyed) return;

    // Sistema de Defesa Automática do Mainframe (Multi-Target Laser Defense)
    _executeDefense(dt);
  }

  void _executeDefense(double dt) {
    final targets = _findEnemiesInRange(model.defenseRange, model.targetCount);
    if (targets.isEmpty) return;

    // Dispara feixes defensivos contra os alvos selecionados
    for (final enemy in targets) {
      final damage = model.laserDps * dt;
      enemy.takeDamage(damage);

      // Efeito visual de feixe de contenção
      if (_attackCooldown <= 0.0) {
        parent?.add(LaserBeamEffect(
          start: position.clone(),
          end: enemy.position.clone(),
          beamColor: themeColor,
          duration: 0.14,
        ));
      }
    }

    if (_attackCooldown <= 0.0) {
      _attackCooldown = 0.16; // Cadência dos feixes de laser
    }
  }

  List<DataPacketComponent> _findEnemiesInRange(double range, int maxTargets) {
    final enemies = getEnemyPackets();
    final inRange = <DataPacketComponent>[];

    for (final enemy in enemies) {
      if (enemy.isMounted && !enemy.isDead) {
        final dist = position.distanceTo(enemy.position);
        if (dist <= range) {
          inRange.add(enemy);
          if (inRange.length >= maxTargets) break;
        }
      }
    }
    return inRange;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;
    final pulse = 0.5 + 0.5 * math.sin(_pulseTimer);

    // 1. Chassi Externo do Gabinete do Servidor
    final chassisRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      const Radius.circular(10),
    );
    final chassisPaint = Paint()
      ..color = AppColors.cardSurface
      ..style = PaintingStyle.fill;
    canvas.drawRRect(chassisRect, chassisPaint);

    // 2. Borda Neon com Brilho do Time
    final borderPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.7 + (pulse * 0.3))
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(chassisRect, borderPaint);

    // 3. Linhas de Refrigeração Líquida (Telas de Acrílico Iluminadas)
    final fluidPaint = Paint()
      ..color = themeColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(8, 8, w - 16, h - 28), const Radius.circular(6)),
      fluidPaint,
    );

    // 4. Lâminas de Servidores e LEDs de Status
    for (int i = 0; i < 4; i++) {
      final slotY = 14.0 + (i * 12.0);
      final linePaint = Paint()
        ..color = AppColors.border
        ..strokeWidth = 1.0;
      canvas.drawLine(Offset(14, slotY), Offset(w - 14, slotY), linePaint);

      // LEDs piscantes
      final isLedOn = ((math.sin(_ledTimer + i) + 1.0) / 2.0) > 0.4;
      final ledPaint = Paint()
        ..color = isLedOn ? themeColor : AppColors.textMuted
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(22, slotY - 3), 2.5, ledPaint);
    }

    // 5. Núcleo de Processamento Central (Ícone / Emblema)
    final corePaint = Paint()
      ..color = themeColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2 - 4), 14, corePaint);

    final innerCorePaint = Paint()
      ..color = AppColors.background
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w / 2, h / 2 - 4), 9, innerCorePaint);

    // 6. Barra de Integridade e Nível de Hardware na Base
    _renderHealthBar(canvas, w, h);
  }

  void _renderHealthBar(Canvas canvas, double w, double h) {
    const barHeight = 8.0;
    final barY = h - 14.0;
    final barWidth = w - 16.0;

    // Fundo da barra
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, barY, barWidth, barHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = const Color(0xFF1E2330));

    // Barra de Vida preenchida
    final pct = (model.hpPercentage / 100.0).clamp(0.0, 1.0);
    final hpColor = pct > 0.5 ? AppColors.bandwidth : (pct > 0.25 ? AppColors.cpuClock : AppColors.redTeam);
    final fillRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(8, barY, barWidth * pct, barHeight),
      const Radius.circular(4),
    );
    canvas.drawRRect(fillRect, Paint()..color = hpColor);

    // Borda da barra
    canvas.drawRRect(
      bgRect,
      Paint()
        ..color = AppColors.border
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );
  }
}
