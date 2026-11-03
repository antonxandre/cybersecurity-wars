import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';

/// Overlay Modal Cinematográfico de Inicialização de Sala / Simulação (Esports Style).
class MatchmakingOverlay extends StatefulWidget {
  final MatchmakingPhase phase;
  final int elapsedSeconds;
  final VoidCallback onCancel;
  final LobbyMode mode;

  const MatchmakingOverlay({
    super.key,
    required this.phase,
    required this.elapsedSeconds,
    required this.onCancel,
    this.mode = LobbyMode.createRoom,
  });

  @override
  State<MatchmakingOverlay> createState() => _MatchmakingOverlayState();
}

class _MatchmakingOverlayState extends State<MatchmakingOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  String _formatTimer(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.phase == MatchmakingPhase.idle) {
      return const SizedBox.shrink();
    }

    final isFound = widget.phase == MatchmakingPhase.found ||
        widget.phase == MatchmakingPhase.launching;
    final statusColor = isFound ? AppColors.bandwidth : AppColors.blueTeam;

    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: Colors.black.withValues(alpha: 0.85),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withValues(alpha: 0.25),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 1. Radar Cibernético Animado
                    SizedBox(
                      width: 120,
                      height: 120,
                      child: AnimatedBuilder(
                        animation: _radarController,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _TacticalRadarPainter(
                              progress: _radarController.value,
                              radarColor: statusColor,
                              isFound: isFound,
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 2. Status e Mensagem
                    Text(
                      switch (widget.phase) {
                        MatchmakingPhase.searching => widget.mode == LobbyMode.createRoom
                            ? 'INICIALIZANDO SALA'
                            : 'PREPARANDO SIMULAÇÃO',
                        MatchmakingPhase.found => widget.mode == LobbyMode.createRoom
                            ? 'SALA PRONTA!'
                            : 'SIMULAÇÃO PRONTA!',
                        MatchmakingPhase.launching => 'CARREGANDO ARENA...',
                        MatchmakingPhase.idle => '',
                      },
                      textAlign: TextAlign.center,
                      style: AppTypography.titleLarge.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      switch (widget.phase) {
                        MatchmakingPhase.searching => widget.mode == LobbyMode.createRoom
                            ? 'Alocando nó seguro e gerando credenciais de sessão...'
                            : 'Carregando rotinas e parâmetros do bot tático...',
                        MatchmakingPhase.found => widget.mode == LobbyMode.createRoom
                            ? 'Perímetro defensivo estabelecido e código reservado.'
                            : 'Defesas e nós adversários configurados.',
                        MatchmakingPhase.launching =>
                          'Estabelecendo conexão segura via TLS 1.3...',
                        MatchmakingPhase.idle => '',
                      },
                      textAlign: TextAlign.center,
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. Tempo Decorrido
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        _formatTimer(widget.elapsedSeconds),
                        style: AppTypography.codeLarge.copyWith(
                          color: Colors.white,
                          letterSpacing: 3.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),

                    // 4. Botão Cancelar (somente durante busca/inicialização)
                    if (widget.phase == MatchmakingPhase.searching)
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.redTeam, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: widget.onCancel,
                          child: Text(
                            'CANCELAR',
                            style: AppTypography.codeMedium.copyWith(
                              color: AppColors.redTeam,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TacticalRadarPainter extends CustomPainter {
  final double progress;
  final Color radarColor;
  final bool isFound;

  _TacticalRadarPainter({
    required this.progress,
    required this.radarColor,
    required this.isFound,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Círculos concêntricos do radar
    final ringPaint = Paint()
      ..color = radarColor.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double i = 0.33; i <= 1.0; i += 0.33) {
      canvas.drawCircle(center, radius * i, ringPaint);
    }

    // Linhas em cruz
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), ringPaint);
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), ringPaint);

    if (isFound) {
      // Pulso de sucesso completo
      final successPaint = Paint()
        ..color = radarColor.withValues(alpha: 0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawCircle(center, radius * 0.8, successPaint);

      final checkPaint = Paint()
        ..color = radarColor
        ..strokeWidth = 4.0
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      path.moveTo(center.dx - 18, center.dy);
      path.lineTo(center.dx - 4, center.dy + 14);
      path.lineTo(center.dx + 20, center.dy - 12);
      canvas.drawPath(path, checkPaint);
      return;
    }

    // Ondas expansivas do radar
    final waveRadius = (progress * radius);
    final wavePaint = Paint()
      ..color = radarColor.withValues(alpha: (1.0 - progress) * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(center, waveRadius, wavePaint);

    // Feixe rotativo
    final sweepAngle = progress * 2 * pi;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          radarColor.withValues(alpha: 0.0),
          radarColor.withValues(alpha: 0.6),
        ],
        stops: const [0.75, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, sweepPaint);
  }

  @override
  bool shouldRepaint(covariant _TacticalRadarPainter oldDelegate) => true;
}
