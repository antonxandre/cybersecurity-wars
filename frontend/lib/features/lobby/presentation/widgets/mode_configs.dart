import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';
import '../viewmodels/lobby_view_model.dart';

/// Painel de configuração para o modo Solo contra IA.
class SoloAiConfig extends StatelessWidget {
  final AiDifficulty selectedDifficulty;
  final ValueChanged<AiDifficulty> onDifficultyChanged;

  const SoloAiConfig({
    super.key,
    required this.selectedDifficulty,
    required this.onDifficultyChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'COMPLEXIDADE DO BOT TÁTICO:',
          style: AppTypography.codeSmall.copyWith(
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: AiDifficulty.values.map((difficulty) {
            final isSelected = selectedDifficulty == difficulty;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: _buildDifficultyCard(difficulty, isSelected),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildDifficultyCard(AiDifficulty difficulty, bool isSelected) {
    final color = difficulty.color;

    return InkWell(
      onTap: () => onDifficultyChanged(difficulty),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.cardSurface.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : AppColors.border,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? color : AppColors.textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    difficulty.title,
                    style: AppTypography.bodySmall.copyWith(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              difficulty.subtitle,
              style: AppTypography.codeSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 9,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Painel de configuração para Criar Sala Multiplayer (Host).
class CreateRoomConfig extends StatelessWidget {
  final bool is2v2;
  final ValueChanged<bool> onToggleMode;
  final String roomCode;
  final VoidCallback onRegenerateCode;
  final List<String> partyMembers;
  final ValueChanged<String>? onJoinRoom;

  const CreateRoomConfig({
    super.key,
    required this.is2v2,
    required this.onToggleMode,
    required this.roomCode,
    required this.onRegenerateCode,
    required this.partyMembers,
    this.onJoinRoom,
  });

  @override
  Widget build(BuildContext context) {
    final maxSlots = is2v2 ? 4 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Linha 1: Alternador 1v1 / 2v2 e Código de Convite
        Row(
          children: [
            // Alternador de Formato
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  _buildToggleItem(
                    label: '1v1 Duelo',
                    isActive: !is2v2,
                    onTap: () => onToggleMode(false),
                  ),
                  _buildToggleItem(
                    label: '2v2 Duplas',
                    isActive: is2v2,
                    onTap: () => onToggleMode(true),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Código da Sala
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.blueTeam.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Text(
                      'CÓDIGO: ',
                      style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                    ),
                    Text(
                      roomCode,
                      style: AppTypography.codeLarge.copyWith(
                        color: AppColors.blueTeam,
                        letterSpacing: 2.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Copiar Código',
                      icon: const Icon(Icons.copy_rounded, size: 16, color: AppColors.blueTeam),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: roomCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Código $roomCode copiado!'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      tooltip: 'Novo Código',
                      icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSecondary),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: onRegenerateCode,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Linha 2: Slots de Jogadores
        Text(
          'SLOTS DA PARTIDA:',
          style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(maxSlots, (index) {
            final isOccupied = index < partyMembers.length;
            final isTeam1 = is2v2 ? index < 2 : index == 0;
            final teamLabel = isTeam1 ? 'TIME AZUL' : 'TIME VERMELHO';
            final teamColor = isTeam1 ? AppColors.blueTeam : AppColors.redTeam;
            final memberName = isOccupied ? partyMembers[index] : 'Aguardando...';

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? teamColor.withValues(alpha: 0.12)
                        : AppColors.cardSurface.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isOccupied ? teamColor.withValues(alpha: 0.6) : AppColors.border,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        teamLabel,
                        style: AppTypography.codeSmall.copyWith(
                          fontSize: 8,
                          color: teamColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            isOccupied ? Icons.person_rounded : Icons.person_outline_rounded,
                            size: 14,
                            color: isOccupied ? Colors.white : AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              memberName,
                              style: AppTypography.bodySmall.copyWith(
                                color: isOccupied ? Colors.white : AppColors.textMuted,
                                fontSize: 10,
                                fontWeight: isOccupied ? FontWeight.bold : FontWeight.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
        if (onJoinRoom != null) ...[
          const SizedBox(height: 12),
          _JoinExistingRoomRow(onJoinRoom: onJoinRoom!),
        ],
      ],
    );
  }

  Widget _buildToggleItem({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.blueTeam.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.codeSmall.copyWith(
            color: isActive ? AppColors.blueTeam : AppColors.textMuted,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _JoinExistingRoomRow extends StatefulWidget {
  final ValueChanged<String> onJoinRoom;

  const _JoinExistingRoomRow({required this.onJoinRoom});

  @override
  State<_JoinExistingRoomRow> createState() => _JoinExistingRoomRowState();
}

class _JoinExistingRoomRowState extends State<_JoinExistingRoomRow> {
  final TextEditingController _controller = TextEditingController();
  bool _isExpanded = false;
  String? _errorText;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final clean = LobbyViewModel.sanitizeAndValidateRoomCode(_controller.text);
    if (clean == null) {
      setState(() => _errorText = 'Código inválido (ex: CYB-709)');
      return;
    }
    setState(() => _errorText = null);
    widget.onJoinRoom(clean);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isExpanded) {
      return Align(
        alignment: Alignment.centerLeft,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.vpn_key_rounded, size: 13, color: AppColors.blueTeam),
                const SizedBox(width: 6),
                Text(
                  'Possui o código de outra sala? Conectar com código',
                  style: AppTypography.codeSmall.copyWith(
                    color: AppColors.blueTeam,
                    decoration: TextDecoration.underline,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blueTeam.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: _controller,
                textCapitalization: TextCapitalization.characters,
                style: AppTypography.codeMedium.copyWith(color: Colors.white, letterSpacing: 2),
                decoration: InputDecoration(
                  hintText: 'DIGITE O CÓDIGO (EX: CYB-709)',
                  hintStyle: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixIcon: const Icon(Icons.vpn_key_rounded, size: 14, color: AppColors.blueTeam),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: AppColors.blueTeam, width: 1.5),
                  ),
                  errorText: _errorText,
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueTeam,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                padding: const EdgeInsets.symmetric(horizontal: 14),
              ),
              icon: const Icon(Icons.login_rounded, size: 14),
              label: Text('CONECTAR', style: AppTypography.codeSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
              onPressed: _submit,
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            tooltip: 'Fechar',
            icon: const Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => setState(() => _isExpanded = false),
          ),
        ],
      ),
    );
  }
}


/// Painel de configuração para Encontrar Sala.
class FindRoomConfig extends StatefulWidget {
  final List<PublicRoom> publicRooms;
  final ValueChanged<String> onJoinRoom;

  const FindRoomConfig({
    super.key,
    required this.publicRooms,
    required this.onJoinRoom,
  });

  @override
  State<FindRoomConfig> createState() => _FindRoomConfigState();
}

class _FindRoomConfigState extends State<FindRoomConfig> {
  final TextEditingController _codeController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _submitCode() {
    final validated = LobbyViewModel.sanitizeAndValidateRoomCode(_codeController.text);
    if (validated == null) {
      setState(() => _errorText = 'Formato inválido (ex: CYB-709)');
      return;
    }
    setState(() => _errorText = null);
    widget.onJoinRoom(validated);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Entrada rápida por código
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  style: AppTypography.codeMedium.copyWith(color: Colors.white, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: 'DIGITE O CÓDIGO (EX: CYB-709)',
                    hintStyle: AppTypography.codeSmall.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    prefixIcon: const Icon(Icons.vpn_key_rounded, size: 16, color: AppColors.tokensLumber),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.tokensLumber, width: 1.5),
                    ),
                    errorText: _errorText,
                  ),
                  onSubmitted: (_) => _submitCode(),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.tokensLumber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                icon: const Icon(Icons.login_rounded, size: 16),
                label: const Text('ENTRAR'),
                onPressed: _submitCode,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Lista de Salas Públicas Ativas (rolagem horizontal ou lista compacta)
        Text(
          'SALAS PÚBLICAS RECENTES:',
          style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, letterSpacing: 1.0),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 60,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.publicRooms.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final room = widget.publicRooms[index];
              return Container(
                width: 250,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            room.code,
                            style: AppTypography.codeSmall.copyWith(
                              color: AppColors.tokensLumber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${room.host} • ${room.mode}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                              fontSize: 9,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${room.ping}ms',
                          style: AppTypography.codeSmall.copyWith(
                            fontSize: 8,
                            color: AppColors.bandwidth,
                          ),
                        ),
                        InkWell(
                          onTap: () => widget.onJoinRoom(room.code),
                          child: Text(
                            'CONECTAR',
                            style: AppTypography.codeSmall.copyWith(
                              fontSize: 9,
                              color: AppColors.tokensLumber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
