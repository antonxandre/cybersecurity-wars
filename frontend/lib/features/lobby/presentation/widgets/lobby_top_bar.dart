import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/lobby_models.dart';

/// Barra superior institucional com saldo de moedas, status de rede e perfil.
class LobbyTopBar extends StatelessWidget {
  final PlayerProfile? profile;
  final AuthUser? user;
  final Color teamColor;

  const LobbyTopBar({
    super.key,
    this.profile,
    this.user,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.95),
        border: const Border(
          bottom: BorderSide(color: AppColors.borderGlow, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Logo & Badge de Jogo
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: teamColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: teamColor, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: teamColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Icon(Icons.shield_rounded, color: teamColor, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'PROMPTSEC',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'ARENA',
                        style: AppTypography.titleMedium.copyWith(
                          color: teamColor,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    'CYBERWARS • LEGION TD',
                    style: AppTypography.codeSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const Spacer(),

          // Ações Globais: Tela Cheia, Configurações, Logout
          IconButton(
            tooltip: 'Alternar Tela Cheia',
            icon: const Icon(Icons.fullscreen_rounded, color: AppColors.textSecondary, size: 22),
            onPressed: () => FullscreenHelper.toggleFullscreen(),
          ),
          IconButton(
            tooltip: 'Configurações de Áudio e Vídeo',
            icon: const Icon(Icons.settings_rounded, color: AppColors.blueTeam, size: 21),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            tooltip: 'Encerrar Sessão (OWASP A01)',
            icon: const Icon(Icons.logout_rounded, color: AppColors.redTeam, size: 21),
            onPressed: () async {
              await AuthService.instance.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }
}
