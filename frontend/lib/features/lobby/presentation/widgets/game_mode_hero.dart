import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';
import 'mode_configs.dart';
import 'play_button.dart';

/// Card Hero Central do modo de jogo (estilo Client Esports AAA).
class GameModeHero extends StatelessWidget {
  final LobbyMode mode;
  final AiDifficulty aiDifficulty;
  final ValueChanged<AiDifficulty> onDifficultyChanged;
  final bool is2v2;
  final ValueChanged<bool> onToggle2v2;
  final String roomCode;
  final VoidCallback onRegenerateRoomCode;
  final List<String> partyMembers;
  final List<PublicRoom> publicRooms;
  final ValueChanged<String> onJoinRoom;
  final VoidCallback onPlayPressed;
  final bool isSearchingMatch;

  const GameModeHero({
    super.key,
    required this.mode,
    required this.aiDifficulty,
    required this.onDifficultyChanged,
    required this.is2v2,
    required this.onToggle2v2,
    required this.roomCode,
    required this.onRegenerateRoomCode,
    required this.partyMembers,
    required this.publicRooms,
    required this.onJoinRoom,
    required this.onPlayPressed,
    required this.isSearchingMatch,
  });

  @override
  Widget build(BuildContext context) {
    final accent = mode.accentColor;

    return Container(
      constraints: const BoxConstraints(minHeight: 460),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.15),
            blurRadius: 20,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 1. Key Art de Fundo com Transição Suave
            Positioned.fill(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: Image.asset(
                  mode.assetImage,
                  key: ValueKey(mode.assetImage),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.25),
                          AppColors.surface,
                          AppColors.background,
                        ],
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 2. Overlay Gradiente Escuro de Alto Contraste
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.95),
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.40),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                    begin: Alignment.bottomLeft,
                    end: Alignment.topRight,
                  ),
                ),
              ),
            ),

            // 3. Conteúdo Tático
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Topo do Hero: Badge & Título
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: accent, width: 1.0),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(mode.icon, size: 14, color: accent),
                                const SizedBox(width: 6),
                                Text(
                                  mode.shortLabel.toUpperCase(),
                                  style: AppTypography.codeSmall.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              mode == LobbyMode.createRoom ? 'SALA DEDICADA' : 'SIMULAÇÃO TÁTICA',
                              style: AppTypography.codeSmall.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        mode.title,
                        style: AppTypography.displayMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 620),
                        child: Text(
                          mode.description,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Centro: Configurações do Modo Selecionado
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderGlow.withValues(alpha: 0.5)),
                    ),
                    child: switch (mode) {
                      LobbyMode.createRoom => CreateRoomConfig(
                          is2v2: is2v2,
                          onToggleMode: onToggle2v2,
                          roomCode: roomCode,
                          onRegenerateCode: onRegenerateRoomCode,
                          partyMembers: partyMembers,
                          onJoinRoom: onJoinRoom,
                        ),
                      LobbyMode.soloAi => SoloAiConfig(
                          selectedDifficulty: aiDifficulty,
                          onDifficultyChanged: onDifficultyChanged,
                        ),
                    },
                  ),

                  const SizedBox(height: 24),

                  // Rodapé: Botão JOGAR Gigante e Indicador de Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      PlayButton(
                        label: switch (mode) {
                          LobbyMode.createRoom => 'CRIAR SALA',
                          LobbyMode.soloAi => 'INICIAR TREINO',
                        },
                        icon: switch (mode) {
                          LobbyMode.createRoom => Icons.add_box_rounded,
                          LobbyMode.soloAi => Icons.play_arrow_rounded,
                        },
                        primaryColor: accent,
                        secondaryColor: mode == LobbyMode.createRoom
                            ? AppColors.blueTeamSecondary
                            : AppColors.coreAiSecondary,
                        isLoading: isSearchingMatch,
                        onPressed: onPlayPressed,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
