import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/models/lobby_models.dart';
import '../viewmodels/lobby_view_model.dart';

/// Painel moderno de navegação e listagem de salas ativas (estilo Esports AAA).
/// Exibe todas as salas disponíveis com status de lotação, regras de sala cheia, ping e slots de jogadores.
class RoomBrowserPanel extends StatefulWidget {
  final List<PublicRoom> rooms;
  final ValueChanged<PublicRoom> onJoinRoom;
  final ValueChanged<String> onJoinByCode;
  final VoidCallback onCreateRoom;
  final VoidCallback onRefresh;

  const RoomBrowserPanel({
    super.key,
    required this.rooms,
    required this.onJoinRoom,
    required this.onJoinByCode,
    required this.onCreateRoom,
    required this.onRefresh,
  });

  @override
  State<RoomBrowserPanel> createState() => _RoomBrowserPanelState();
}

class _RoomBrowserPanelState extends State<RoomBrowserPanel> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  String _selectedFilter = 'TODAS'; // 'TODAS', 'DISPONÍVEIS', '1v1', '2v2'
  String? _codeErrorText;
  bool _isDirectCodeOpen = false;

  @override
  void dispose() {
    _searchController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  List<PublicRoom> get _filteredRooms {
    final query = _searchController.text.trim().toLowerCase();
    return widget.rooms.where((room) {
      // 1. Filtro de texto por código ou host
      if (query.isNotEmpty) {
        final matchesCode = room.code.toLowerCase().contains(query);
        final matchesHost = room.host.toLowerCase().contains(query);
        if (!matchesCode && !matchesHost) return false;
      }

      // 2. Filtro de categoria
      switch (_selectedFilter) {
        case 'DISPONÍVEIS':
          return !room.isFull;
        case '1v1':
          return room.mode.contains('1v1');
        case '2v2':
          return room.mode.contains('2v2');
        case 'TODAS':
        default:
          return true;
      }
    }).toList();
  }

  void _submitDirectCode() {
    final validated = LobbyViewModel.sanitizeAndValidateRoomCode(_codeController.text);
    if (validated == null) {
      setState(() => _codeErrorText = 'Formato inválido (ex: CYB-709)');
      return;
    }
    setState(() => _codeErrorText = null);
    widget.onJoinByCode(validated);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredRooms;
    final totalAvailable = widget.rooms.where((r) => !r.isFull).length;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGlow.withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.blueTeam.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Cabeçalho Institucional do Navegador de Salas
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                border: Border(bottom: BorderSide(color: AppColors.border.withValues(alpha: 0.6))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.blueTeam.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.blueTeam.withValues(alpha: 0.5)),
                    ),
                    child: const Icon(Icons.dns_rounded, size: 20, color: AppColors.blueTeam),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALAS ATIVAS & LOBBIES',
                        style: AppTypography.displayMedium.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
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
                            '${widget.rooms.length} SALAS NO SERVIDOR • $totalAvailable COM VAGAS',
                            style: AppTypography.codeSmall.copyWith(
                              fontSize: 10,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Botão de Atualização
                  IconButton(
                    tooltip: 'Atualizar Salas',
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.blueTeam),
                    onPressed: widget.onRefresh,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.cardSurface,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Botão Primário: CRIAR SALA
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blueTeam,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      elevation: 4,
                      shadowColor: AppColors.blueTeam.withValues(alpha: 0.5),
                    ),
                    icon: const Icon(Icons.add_box_rounded, size: 18),
                    label: Text(
                      'CRIAR SALA',
                      style: AppTypography.codeSmall.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    onPressed: widget.onCreateRoom,
                  ),
                ],
              ),
            ),

            // 2. Barra de Filtros, Pesquisa e Conexão Rápida
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                children: [
                  Row(
                    children: [
                      // Campo de busca por texto
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _searchController,
                            onChanged: (_) => setState(() {}),
                            style: AppTypography.bodySmall.copyWith(color: Colors.white, fontSize: 12),
                            decoration: InputDecoration(
                              hintText: 'Buscar por código da sala ou host...',
                              hintStyle: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 11),
                              prefixIcon: const Icon(Icons.search_rounded, size: 16, color: AppColors.textSecondary),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear_rounded, size: 16, color: AppColors.textMuted),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: AppColors.cardSurface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.border),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: const BorderSide(color: AppColors.blueTeam, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Botão Alternador "Entrar por Código"
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _isDirectCodeOpen ? AppColors.tokensLumber : AppColors.textPrimary,
                          backgroundColor: _isDirectCodeOpen
                              ? AppColors.tokensLumber.withValues(alpha: 0.15)
                              : AppColors.cardSurface,
                          side: BorderSide(
                            color: _isDirectCodeOpen ? AppColors.tokensLumber : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        icon: const Icon(Icons.vpn_key_rounded, size: 15),
                        label: Text(
                          'CÓDIGO DIRETO',
                          style: AppTypography.codeSmall.copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() => _isDirectCodeOpen = !_isDirectCodeOpen);
                        },
                      ),
                    ],
                  ),

                  // Área Expansível para Código Direto
                  if (_isDirectCodeOpen) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.cardSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.tokensLumber.withValues(alpha: 0.5)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 38,
                              child: TextField(
                                controller: _codeController,
                                textCapitalization: TextCapitalization.characters,
                                style: AppTypography.codeMedium.copyWith(color: Colors.white, letterSpacing: 2),
                                decoration: InputDecoration(
                                  hintText: 'DIGITE O CÓDIGO (EX: CYB-709)',
                                  hintStyle: AppTypography.codeSmall.copyWith(color: AppColors.textMuted, fontSize: 10),
                                  filled: true,
                                  fillColor: AppColors.surface,
                                  prefixIcon: const Icon(Icons.pin_rounded, size: 16, color: AppColors.tokensLumber),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppColors.border),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(6),
                                    borderSide: const BorderSide(color: AppColors.tokensLumber, width: 1.5),
                                  ),
                                  errorText: _codeErrorText,
                                ),
                                onSubmitted: (_) => _submitDirectCode(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.tokensLumber,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            ),
                            onPressed: _submitDirectCode,
                            child: Text(
                              'CONECTAR',
                              style: AppTypography.codeSmall.copyWith(fontWeight: FontWeight.bold, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 12),

                  // Chips de Filtro
                  Row(
                    children: [
                      Text(
                        'FILTRAR:',
                        style: AppTypography.codeSmall.copyWith(
                          fontSize: 10,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ...['TODAS', 'DISPONÍVEIS', '1v1', '2v2'].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: InkWell(
                            onTap: () => setState(() => _selectedFilter = filter),
                            borderRadius: BorderRadius.circular(6),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.blueTeam.withValues(alpha: 0.2)
                                    : AppColors.cardSurface,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: isSelected ? AppColors.blueTeam : AppColors.border,
                                  width: isSelected ? 1.2 : 1.0,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: AppTypography.codeSmall.copyWith(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.blueTeam : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const Divider(color: AppColors.border, height: 1),

            // 3. Lista de Salas Ativas
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off_rounded, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                          const SizedBox(height: 12),
                          Text(
                            'NENHUMA SALA ENCONTRADA',
                            style: AppTypography.codeMedium.copyWith(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tente mudar os filtros ou crie sua própria sala dedicada.',
                            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 11),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blueTeam,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            icon: const Icon(Icons.add_box_rounded, size: 16),
                            label: const Text('CRIAR SALA AGORA'),
                            onPressed: widget.onCreateRoom,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final room = filtered[index];
                        return _buildRoomCard(context, room);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Constrói o cartão de cada sala pública com regras estritas de sala cheia e ping
  Widget _buildRoomCard(BuildContext context, PublicRoom room) {
    final isFull = room.isFull;
    final pingColor = room.pingColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isFull
            ? AppColors.cardSurface.withValues(alpha: 0.35)
            : AppColors.cardSurface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFull
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.borderGlow.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          // Ícone e Código da Sala
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: isFull
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.blueTeam.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isFull ? AppColors.textMuted : AppColors.blueTeam,
                width: 1.0,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isFull ? Icons.lock_rounded : Icons.lock_open_rounded,
                  size: 14,
                  color: isFull ? AppColors.textMuted : AppColors.blueTeam,
                ),
                const SizedBox(height: 2),
                Text(
                  room.code,
                  style: AppTypography.codeSmall.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    fontSize: 11,
                    color: isFull ? AppColors.textMuted : Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Informações do Host e Modo
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      room.host,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isFull ? AppColors.textSecondary : Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
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
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Jogadores Conectados
                Row(
                  children: [
                    Icon(
                      Icons.people_alt_rounded,
                      size: 13,
                      color: isFull ? AppColors.redTeam : AppColors.bandwidth,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${room.players}/${room.maxPlayers} JOGADORES',
                      style: AppTypography.codeSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isFull ? AppColors.redTeam : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Indicador de Ping
                    Icon(Icons.wifi_rounded, size: 12, color: pingColor),
                    const SizedBox(width: 4),
                    Text(
                      '${room.ping}ms',
                      style: AppTypography.codeSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: pingColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Status Badge e Botão de Ação
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Badge de Status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFull
                      ? AppColors.redTeam.withValues(alpha: 0.15)
                      : AppColors.bandwidth.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isFull ? AppColors.redTeam : AppColors.bandwidth,
                    width: 1.0,
                  ),
                ),
                child: Text(
                  isFull ? 'SALA CHEIA' : 'DISPONÍVEL (${room.availableSlots} VAGA${room.availableSlots > 1 ? 'S' : ''})',
                  style: AppTypography.codeSmall.copyWith(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isFull ? AppColors.redTeam : AppColors.bandwidth,
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Botão de Entrada ou Desabilitado
              SizedBox(
                height: 32,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFull ? Colors.white.withValues(alpha: 0.08) : AppColors.blueTeam,
                    foregroundColor: isFull ? AppColors.textMuted : Colors.black,
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.05),
                    disabledForegroundColor: AppColors.textMuted,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: Icon(
                    isFull ? Icons.block_rounded : Icons.login_rounded,
                    size: 13,
                  ),
                  label: Text(
                    isFull ? 'CHEIA' : 'ENTRAR',
                    style: AppTypography.codeSmall.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      letterSpacing: 1.0,
                    ),
                  ),
                  onPressed: isFull
                      ? null // Regra estrita: botão desabilitado se sala cheia
                      : () => widget.onJoinRoom(room),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
