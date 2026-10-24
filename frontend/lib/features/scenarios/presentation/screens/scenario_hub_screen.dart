import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/scenario_model.dart';

/// Tela do Hub Tático de Seleção de Cenários (Scenario Hub).
/// Conecta o operador à Arena e oferece ação de Logout com invalidação de sessão.
class ScenarioHubScreen extends StatelessWidget {
  const ScenarioHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final currentUser = authService.currentUser ??
        const AuthUser(
          id: 'demo_user',
          username: 'Operador Ghost',
          email: 'operador@promptsec.arena',
          role: UserRole.blueTeam,
        );

    final isBlue = currentUser.role == UserRole.blueTeam;
    final roleColor = isBlue ? AppColors.blueTeam : AppColors.redTeam;
    final scenarios = ScenarioModel.catalog;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header Tático
            _buildHubHeader(context, currentUser, roleColor),

            // Conteúdo Principal com Lista de Cenários
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Banner de Status da Operação
                        _buildOperationBanner(currentUser, roleColor),
                        const SizedBox(height: 24),

                        // Título da Seção
                        Row(
                          children: [
                            Icon(Icons.hub_rounded, color: roleColor, size: 20),
                            const SizedBox(width: 8),
                            Text('CENÁRIOS DE BATALHA DISPONÍVEIS', style: AppTypography.titleLarge),
                            const Spacer(),
                            Text(
                              '${scenarios.length} SIMULAÇÕES ATIVAS',
                              style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Lista / Grid de Cards de Cenários
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;
                            if (isWide) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 1.35,
                                ),
                                itemCount: scenarios.length,
                                itemBuilder: (context, index) {
                                  return _buildScenarioCard(context, scenarios[index], currentUser, roleColor);
                                },
                              );
                            } else {
                              return ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: scenarios.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 16),
                                itemBuilder: (context, index) {
                                  return _buildScenarioCard(context, scenarios[index], currentUser, roleColor);
                                },
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHubHeader(BuildContext context, AuthUser user, Color roleColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1.5)),
      ),
      child: Row(
        children: [
          // Logo & Título
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: roleColor.withOpacity(0.5)),
            ),
            child: Icon(Icons.security_rounded, color: roleColor, size: 22),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('PROMPTSEC ARENA', style: AppTypography.titleMedium.copyWith(letterSpacing: 1.5)),
              Text(
                'HUB TÁTICO MULTICAMADAS // v0.4.0',
                style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
              ),
            ],
          ),
          const Spacer(),

          // Badge do Operador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: roleColor.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  user.role == UserRole.blueTeam ? Icons.shield_rounded : Icons.flash_on_rounded,
                  color: roleColor,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  user.role.displayName.toUpperCase(),
                  style: AppTypography.codeSmall.copyWith(color: roleColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '| ${user.username}',
                  style: AppTypography.codeSmall.copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Botão de Logout com Destruição de Sessão
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textMuted,
              side: const BorderSide(color: AppColors.border),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () {
              AuthService.instance.logout();
              context.go('/login');
            },
            icon: const Icon(Icons.logout_rounded, size: 16),
            label: Text('SAIR', style: AppTypography.codeSmall),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationBanner(AuthUser user, Color roleColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withOpacity(0.3)),
        boxShadow: AppColors.neonGlow(roleColor, blur: 14, spread: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PERÍMETRO ATIVO',
                        style: AppTypography.codeSmall.copyWith(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'STATUS: PROTOCOLOS OPERACIONAIS EM VIGOR',
                      style: AppTypography.codeSmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text('SELECIONE O VETOR DE ENFRENTAMENTO', style: AppTypography.titleLarge),
                const SizedBox(height: 6),
                Text(
                  'Escolha um cenário para iniciar a simulação tática. Defenda o Core LLM e a infraestrutura de redes ou execute exploração e quebra de barreiras.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(
    BuildContext context,
    ScenarioModel scenario,
    AuthUser user,
    Color roleColor,
  ) {
    final isBlue = user.role == UserRole.blueTeam;
    final objective = isBlue ? scenario.objectiveBlue : scenario.objectiveRed;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scenario.categoryColor.withOpacity(0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: scenario.categoryColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scenario.categoryColor.withOpacity(0.4)),
                ),
                child: Icon(scenario.icon, color: scenario.categoryColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      scenario.categoryTag,
                      style: AppTypography.codeSmall.copyWith(
                        color: scenario.categoryColor,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      scenario.title,
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Dificuldade em Estrelas
              Row(
                children: List.generate(3, (i) {
                  return Icon(
                    i < scenario.difficulty ? Icons.star_rounded : Icons.star_border_rounded,
                    color: i < scenario.difficulty ? AppColors.cpuClock : AppColors.textMuted,
                    size: 16,
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Descrição do Cenário
          Text(
            scenario.description,
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),

          // Objetivo Tático Específico da Equipe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  isBlue ? Icons.shield_outlined : Icons.track_changes_rounded,
                  color: roleColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'MISSÃO: $objective',
                    style: AppTypography.codeSmall.copyWith(fontSize: 10, color: AppColors.textPrimary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Botão Entrar na Arena
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: scenario.categoryColor,
                foregroundColor: AppColors.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                context.go('/arena');
              },
              icon: const Icon(Icons.play_arrow_rounded, size: 18),
              label: Text(
                'INICIAR SIMULAÇÃO',
                style: AppTypography.codeSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
