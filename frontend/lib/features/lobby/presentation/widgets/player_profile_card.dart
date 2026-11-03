import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/lobby_models.dart';
import 'lobby_panel.dart';

/// Card de Estatísticas do Perfil do usuário logado (sem informações de ELO).
class PlayerProfileCard extends StatelessWidget {
  final PlayerProfile profile;
  final AuthUser? user;
  final Color teamColor;

  const PlayerProfileCard({
    super.key,
    required this.profile,
    this.user,
    required this.teamColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeUser = user ??
        AuthService.instance.currentUser ??
        const AuthUser(
          id: 'usr_ghost',
          username: 'Operador Ghost',
          email: 'operador@promptsec.arena',
          role: UserRole.blueTeam,
        );

    return LobbyPanel(
      title: 'ESTATÍSTICAS DO PERFIL',
      icon: Icons.analytics_rounded,
      accentColor: teamColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Identificação do Usuário Logado
          Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: teamColor.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: teamColor, width: 2.0),
                      boxShadow: [
                        BoxShadow(
                          color: teamColor.withValues(alpha: 0.35),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        activeUser.username.isNotEmpty ? activeUser.username[0].toUpperCase() : 'U',
                        style: AppTypography.titleLarge.copyWith(
                          color: teamColor,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: teamColor, width: 1.0),
                      ),
                      child: Text(
                        'NV.${profile.level}',
                        style: AppTypography.codeSmall.copyWith(
                          fontSize: 8,
                          color: teamColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activeUser.username,
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: teamColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: teamColor, blurRadius: 4),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          activeUser.roleDisplayName.toUpperCase(),
                          style: AppTypography.codeSmall.copyWith(
                            color: teamColor,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. Barra de Progresso de XP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EXPERIÊNCIA TÁTICA (XP)',
                style: AppTypography.codeSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${profile.currentXp} / ${profile.xpToNext} XP',
                style: AppTypography.codeSmall.copyWith(
                  color: teamColor,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: profile.xpProgress,
              minHeight: 6,
              backgroundColor: AppColors.cardSurface,
              valueColor: AlwaysStoppedAnimation<Color>(teamColor),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Grid de Estatísticas do Usuário Logado
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'WIN RATE',
                  value: '${profile.winRate.toStringAsFixed(1)}%',
                  icon: Icons.trending_up_rounded,
                  color: AppColors.bandwidth,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  label: 'VITÓRIAS',
                  value: '${profile.wins}',
                  icon: Icons.emoji_events_rounded,
                  color: AppColors.bandwidth,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'DERROTAS',
                  value: '${profile.losses}',
                  icon: Icons.cancel_outlined,
                  color: AppColors.redTeam,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  label: 'VITÓRIAS SEGUIDAS',
                  value: '${profile.winStreak}x',
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.bitsGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  label: 'TOTAL DE EXPURGOS',
                  value: '${profile.totalPurges}',
                  icon: Icons.security_rounded,
                  color: AppColors.blueTeam,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildStatCard(
                  label: 'PARTIDAS TOTAIS',
                  value: '${profile.matches}',
                  icon: Icons.sports_esports_rounded,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: AppTypography.codeMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                Text(
                  label,
                  style: AppTypography.codeSmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 8,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
