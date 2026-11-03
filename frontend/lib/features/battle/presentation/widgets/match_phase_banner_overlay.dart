import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/match_state.dart';

/// Banner tático holográfico para transições de fase e ondas (estilo Esports / MOBA).
/// Mostra um aviso imersivo animado no centro da tela que desliza, brilha e desaparece.
class MatchPhaseBannerOverlay extends StatefulWidget {
  final MatchPhase phase;
  final int currentWave;
  final int totalWaves;

  const MatchPhaseBannerOverlay({
    super.key,
    required this.phase,
    required this.currentWave,
    required this.totalWaves,
  });

  @override
  State<MatchPhaseBannerOverlay> createState() => _MatchPhaseBannerOverlayState();
}

class _MatchPhaseBannerOverlayState extends State<MatchPhaseBannerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _scaleAnimation;

  String _title = '';
  String _subtitle = '';
  Color _accentColor = AppColors.blueTeam;
  IconData _icon = Icons.shield_rounded;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _fadeAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 25,
      ),
    ]).animate(_controller);

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutBack),
    ));

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
      ),
    );

    _configureContent();
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant MatchPhaseBannerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.phase != oldWidget.phase || widget.currentWave != oldWidget.currentWave) {
      _configureContent();
      _controller.reset();
      _controller.forward();
    }
  }

  void _configureContent() {
    switch (widget.phase) {
      case MatchPhase.preparation:
        _title = 'TURNO ZERO: ALOCAÇÃO DE DEFESAS';
        _subtitle = 'Posicione Bastiões e invista em mineradores antes do tempo esgotar';
        _accentColor = AppColors.blueTeam;
        _icon = Icons.build_circle_rounded;
        break;
      case MatchPhase.battle:
        _title = 'COMBATE ATIVO — ONDA ${widget.currentWave}/${widget.totalWaves}';
        _subtitle = 'Tráfego hostil em rotação. Monitore integridade de portas e firewalls';
        _accentColor = AppColors.redTeam;
        _icon = Icons.warning_amber_rounded;
        break;
      case MatchPhase.victory:
        _title = 'MAINFRAME ADVERSÁRIO NEUTRALIZADO';
        _subtitle = 'Vitória incontestável! Integridade da rede azul preservada';
        _accentColor = AppColors.bandwidth;
        _icon = Icons.emoji_events_rounded;
        break;
      case MatchPhase.defeat:
        _title = 'BRECHA CRÍTICA: MAINFRAME COMPROMETIDO';
        _subtitle = 'Defesas superadas. Reinicie o protocolo e reavalie os filtros';
        _accentColor = AppColors.redTeam;
        _icon = Icons.gpp_bad_rounded;
        break;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_fadeAnimation.value <= 0.0) {
            return const SizedBox.shrink();
          }

          return Center(
            child: Opacity(
              opacity: _fadeAnimation.value,
              child: SlideTransition(
                position: _slideAnimation,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    decoration: BoxDecoration(
                      color: AppColors.background.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: _accentColor, width: 1.8),
                      boxShadow: [
                        BoxShadow(
                          color: _accentColor.withValues(alpha: 0.35),
                          blurRadius: 28,
                          spreadRadius: 2,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.7),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _accentColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.zero,
                            border: Border.all(color: _accentColor.withValues(alpha: 0.6)),
                          ),
                          child: Icon(_icon, color: _accentColor, size: 30),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: AppTypography.codeMedium.copyWith(
                                color: _accentColor,
                                fontWeight: FontWeight.w900,
                                fontSize: 18.0,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              _subtitle,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary.withValues(alpha: 0.9),
                                fontSize: 13.5,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
