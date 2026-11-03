import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';

/// Sala de Espera (Waiting Room) interativa estilo Esports AAA.
/// Onde os operadores aguardam outros jogadores antes de iniciar a partida na Arena.
class WaitingRoomView extends StatelessWidget {
  final PublicRoom room;
  final VoidCallback onLeaveRoom;
  final VoidCallback onStartMatch;
  final VoidCallback onSimulateJoin;
  final ValueChanged<LobbyFriend>? onInviteFriend;
  final List<LobbyFriend> availableFriends;

  const WaitingRoomView({
    super.key,
    required this.room,
    required this.onLeaveRoom,
    required this.onStartMatch,
    required this.onSimulateJoin,
    this.onInviteFriend,
    this.availableFriends = const [],
  });

  @override
  Widget build(BuildContext context) {
    final is2v2 = room.mode.contains('2v2');
    final maxSlots = room.maxPlayers;
    final players = room.playerNames.isNotEmpty ? room.playerNames : [room.host];
    final isReadyToStart = players.length >= 2;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blueTeam.withValues(alpha: 0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppColors.blueTeam.withValues(alpha: 0.15),
            blurRadius: 25,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Barra Superior da Sala de Espera
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
              ),
              child: Row(
                children: [
                  // Botão Voltar / Sair da Sala
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      backgroundColor: AppColors.cardSurface,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 16),
                    label: Text(
                      'SAIR DA SALA',
                      style: AppTypography.codeSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                    onPressed: onLeaveRoom,
                  ),
                  const SizedBox(width: 16),

                  // Título da Sala
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.blueTeam.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.blueTeam.withValues(alpha: 0.6)),
                              ),
                              child: Text(
                                'SALA DE ESPERA',
                                style: AppTypography.codeSmall.copyWith(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.blueTeam,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                room.mode.toUpperCase(),
                                style: AppTypography.codeSmall.copyWith(
                                  fontSize: 9,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Indicador de Ping
                            Icon(Icons.wifi_rounded, size: 12, color: room.pingColor),
                            const SizedBox(width: 4),
                            Text(
                              '${room.ping}ms',
                              style: AppTypography.codeSmall.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: room.pingColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'HOST: ${room.host.toUpperCase()}',
                          style: AppTypography.displayMedium.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Código da Sala com Cópia Rápida
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.cardSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.blueTeam.withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'CÓDIGO DE CONVITE',
                              style: AppTypography.codeSmall.copyWith(fontSize: 8, color: AppColors.textMuted),
                            ),
                            Text(
                              room.code,
                              style: AppTypography.codeLarge.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: AppColors.blueTeam,
                                letterSpacing: 2.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: 'Copiar Código de Convite',
                          icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.blueTeam),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: room.code));
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Código ${room.code} copiado para a área de transferência!'),
                                duration: const Duration(seconds: 2),
                                backgroundColor: AppColors.surface,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. Banner de Status dos Operadores
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              color: AppColors.cardSurface.withValues(alpha: 0.4),
              child: Row(
                children: [
                  Icon(
                    room.isFull ? Icons.check_circle_rounded : Icons.hourglass_top_rounded,
                    size: 16,
                    color: room.isFull ? AppColors.bandwidth : AppColors.cpuClock,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    room.isFull
                        ? 'SALA LOTADA (${players.length}/$maxSlots) • PRONTO PARA O COMBATE'
                        : 'AGUARDANDO OPERADORES (${players.length}/$maxSlots CONECTADOS)',
                    style: AppTypography.codeSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: room.isFull ? AppColors.bandwidth : AppColors.cpuClock,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const Spacer(),
                  // Botão de Simulação de Entrada (ideal para testar UI de espera)
                  if (!room.isFull)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.tokensLumber,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      ),
                      icon: const Icon(Icons.person_add_rounded, size: 14),
                      label: Text(
                        'SIMULAR ENTRADA',
                        style: AppTypography.codeSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                      onPressed: onSimulateJoin,
                    ),
                ],
              ),
            ),

            // 3. Grid dos Slots de Jogadores (Pods Táticos)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Coluna 1: Time Azul (Defensores / Host)
                    Expanded(
                      child: _buildTeamColumn(
                        teamName: 'TIME AZUL (DEFESA)',
                        teamColor: AppColors.blueTeam,
                        teamIcon: Icons.shield_rounded,
                        startIndex: 0,
                        count: is2v2 ? 2 : 1,
                        players: players,
                        context: context,
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Divisor Central de Duelo
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.cardSurface,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.borderGlow),
                            ),
                            child: Text(
                              'VS',
                              style: AppTypography.codeLarge.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),

                    // Coluna 2: Time Vermelho (Invasores)
                    Expanded(
                      child: _buildTeamColumn(
                        teamName: 'TIME VERMELHO (ATAQUE)',
                        teamColor: AppColors.redTeam,
                        teamIcon: Icons.dangerous_rounded,
                        startIndex: is2v2 ? 2 : 1,
                        count: is2v2 ? 2 : 1,
                        players: players,
                        context: context,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 4. Rodapé Tático com Ações
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                border: Border(top: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    isReadyToStart
                        ? 'Todos os times possuem operadores. O Host pode iniciar o combate.'
                        : 'Aguardando pelo menos 1 adversário para iniciar a batalha.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const Spacer(),
                  // Botão de Iniciar Partida
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isReadyToStart ? AppColors.bandwidth : AppColors.cardSurface,
                      foregroundColor: isReadyToStart ? Colors.black : AppColors.textMuted,
                      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: isReadyToStart ? 6 : 0,
                      shadowColor: AppColors.bandwidth.withValues(alpha: 0.6),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 20),
                    label: Text(
                      'INICIAR PARTIDA',
                      style: AppTypography.codeMedium.copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                        letterSpacing: 1.2,
                      ),
                    ),
                    onPressed: isReadyToStart ? onStartMatch : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamColumn({
    required String teamName,
    required Color teamColor,
    required IconData teamIcon,
    required int startIndex,
    required int count,
    required List<String> players,
    required BuildContext context,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho do Time
        Row(
          children: [
            Icon(teamIcon, size: 16, color: teamColor),
            const SizedBox(width: 8),
            Text(
              teamName,
              style: AppTypography.codeSmall.copyWith(
                color: teamColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Slots do Time
        Expanded(
          child: Column(
            children: List.generate(count, (i) {
              final slotIndex = startIndex + i;
              final isOccupied = slotIndex < players.length;
              final playerName = isOccupied ? players[slotIndex] : null;
              final isHost = slotIndex == 0;

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildPlayerSlot(
                    isOccupied: isOccupied,
                    playerName: playerName,
                    isHost: isHost,
                    teamColor: teamColor,
                    context: context,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerSlot({
    required bool isOccupied,
    required String? playerName,
    required bool isHost,
    required Color teamColor,
    required BuildContext context,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOccupied
            ? teamColor.withValues(alpha: 0.10)
            : AppColors.cardSurface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOccupied
              ? teamColor.withValues(alpha: 0.6)
              : AppColors.border.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: isOccupied
          ? Row(
              children: [
                // Avatar Tático
                CircleAvatar(
                  radius: 22,
                  backgroundColor: teamColor.withValues(alpha: 0.25),
                  child: Icon(Icons.person_rounded, color: teamColor, size: 24),
                ),
                const SizedBox(width: 14),
                // Nome e Tags
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              playerName ?? 'Operador',
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHost)
                            Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.cpuClock.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: AppColors.cpuClock, width: 0.8),
                              ),
                              child: Text(
                                'HOST',
                                style: AppTypography.codeSmall.copyWith(
                                  fontSize: 8,
                                  color: AppColors.cpuClock,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: AppColors.bandwidth,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PRONTO PARA COMBATE',
                            style: AppTypography.codeSmall.copyWith(
                              fontSize: 9,
                              color: AppColors.bandwidth,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded, size: 28, color: AppColors.textMuted.withValues(alpha: 0.5)),
                  const SizedBox(height: 6),
                  Text(
                    'VAGA ABERTA',
                    style: AppTypography.codeSmall.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Aguardando conexão...',
                    style: AppTypography.codeSmall.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
