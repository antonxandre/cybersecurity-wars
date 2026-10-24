import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';

enum LobbyTab { soloAi, createRoom, findRoom }

/// Tela unificada do Lobby Multiplayer e Treino Solo (Legion TD / CyberWars).
class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  LobbyTab _currentTab = LobbyTab.soloAi;
  int _selectedAiDifficulty = 1; // 0: Fácil, 1: Médio, 2: Especialista
  bool _is2v2 = true;
  late String _generatedRoomCode;
  final TextEditingController _roomCodeInputController = TextEditingController();

  final List<({String code, String host, String mode, int players, int maxPlayers, int ping})> _publicRooms = [
    (code: 'CYB-709', host: 'ZeroDay_Hunter', mode: '2v2 Duplas', players: 3, maxPlayers: 4, ping: 18),
    (code: 'NET-404', host: 'SynFlood_Master', mode: '1v1 Duelo', players: 1, maxPlayers: 2, ping: 24),
    (code: 'SEC-888', host: 'KernelPanic', mode: '2v2 Duplas', players: 2, maxPlayers: 4, ping: 32),
  ];

  @override
  void initState() {
    super.initState();
    _regenerateRoomCode();
  }

  @override
  void dispose() {
    _roomCodeInputController.dispose();
    super.dispose();
  }

  void _regenerateRoomCode() {
    final rand = Random();
    final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    final part2 = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    setState(() {
      _generatedRoomCode = '$part1-$part2';
    });
  }

  void _launchMatch({required String matchType, String? roomCode}) {
    context.go('/arena');
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final currentUser = authService.currentUser ??
        const AuthUser(
          id: 'guest_operator',
          username: 'Operador Ghost',
          email: 'operador@promptsec.arena',
          role: UserRole.blueTeam,
        );

    final isBlue = currentUser.role == UserRole.blueTeam;
    final teamColor = isBlue ? AppColors.blueTeam : AppColors.redTeam;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header Tático
            _buildLobbyHeader(context, currentUser, teamColor),

            // Conteúdo Principal
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Banner explicativo do modo Legion TD Multiplayer
                        _buildLegionExplanationBanner(),
                        const SizedBox(height: 20),

                        // Seletor de Abas (Solo IA / Criar Sala / Buscar Sala)
                        _buildTabSelector(teamColor),
                        const SizedBox(height: 20),

                        // Conteúdo da Aba Ativa
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          child: switch (_currentTab) {
                            LobbyTab.soloAi => _buildSoloAiPanel(teamColor),
                            LobbyTab.createRoom => _buildCreateRoomPanel(teamColor),
                            LobbyTab.findRoom => _buildFindRoomPanel(teamColor),
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

  Widget _buildLobbyHeader(BuildContext context, AuthUser user, Color teamColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(bottom: BorderSide(color: AppColors.borderGlow, width: 1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: teamColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: teamColor, width: 1.5),
            ),
            child: Icon(Icons.shield_rounded, color: teamColor, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('PROMPTSEC ARENA', style: AppTypography.titleLarge),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.tokensLumber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.tokensLumber, width: 1),
                    ),
                    child: Text(
                      'LEGION TD MULTIPLAYER',
                      style: AppTypography.codeSmall.copyWith(
                        color: AppColors.tokensLumber,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
              Text(
                'Defenda o Mainframe • Mine Tokens • Envie Malwares em Tempo Real',
                style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const Spacer(),

          // Tag de perfil do operador
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.borderGlow),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 10,
                  backgroundColor: teamColor,
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : 'O',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                Text(user.username, style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Botão Fullscreen
          IconButton(
            tooltip: 'Alternar Tela Cheia',
            icon: const Icon(Icons.fullscreen_rounded, color: AppColors.textPrimary, size: 22),
            onPressed: () => FullscreenHelper.toggleFullscreen(),
          ),

          // Botão de Logout
          IconButton(
            tooltip: 'Encerrar Sessão (OWASP A01)',
            icon: const Icon(Icons.logout_rounded, color: AppColors.redTeam, size: 22),
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

  Widget _buildLegionExplanationBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.tokensLumber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.hub_rounded, color: AppColors.tokensLumber, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A ESSÊNCIA DO LEGION TD CIBERNÉTICO',
                  style: AppTypography.titleMedium.copyWith(color: AppColors.tokensLumber),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gaste Bits para construir defesas e recrutar mineradores. Gaste Tokens para aprimorar o Mainframe (CPU, RAM, Disco) ou enviar vírus para o oponente, aumentando sua renda permanente de Bits a cada rodada!',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(Color teamColor) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTabButton(
              tab: LobbyTab.soloAi,
              label: 'Jogar com uma IA',
              icon: Icons.smart_toy_rounded,
              accentColor: AppColors.coreAi,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              tab: LobbyTab.createRoom,
              label: 'Criar Sala (Host)',
              icon: Icons.add_circle_outline_rounded,
              accentColor: AppColors.blueTeam,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildTabButton(
              tab: LobbyTab.findRoom,
              label: 'Encontrar Sala',
              icon: Icons.search_rounded,
              accentColor: AppColors.tokensLumber,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required LobbyTab tab,
    required String label,
    required IconData icon,
    required Color accentColor,
  }) {
    final isSelected = _currentTab == tab;

    return InkWell(
      onTap: () => setState(() => _currentTab = tab),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? accentColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? accentColor : AppColors.textMuted, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTypography.bodyMedium.copyWith(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoloAiPanel(Color teamColor) {
    return Container(
      key: const ValueKey('solo_ai_panel'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology_rounded, color: AppColors.coreAi, size: 24),
              const SizedBox(width: 10),
              Text('TREINAMENTO TÁTICO CONTRA BOT SCRIPTADO', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enfrente uma inteligência artificial em um mapa panorâmico contínuo. O bot constrói defesas no Campo 2, aprimora o Mainframe Red e envia vírus coordenados contra o seu grid.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),

          // Seletor de Dificuldade
          Text('SELECIONE A COMPLEXIDADE DO BOT:', style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDifficultyOption(
                  level: 0,
                  title: 'Recruta (Fácil)',
                  subtitle: 'IA passiva, foco em defesas simples e sondas leves.',
                  color: AppColors.blueTeam,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDifficultyOption(
                  level: 1,
                  title: 'Operador (Médio)',
                  subtitle: 'IA balanceada, recruta mineradores e envia SYN Floods.',
                  color: AppColors.cpuClock,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDifficultyOption(
                  level: 2,
                  title: 'Mestre (Especialista)',
                  subtitle: 'IA agressiva, combos de Trojan e upgrades de Mainframe.',
                  color: AppColors.redTeam,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Botão Iniciar Partida Solo
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.coreAi,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text(
                'INICIAR PARTIDA SOLO CONTRA IA',
                style: AppTypography.titleMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _launchMatch(matchType: 'SOLO_AI'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyOption({
    required int level,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final isSelected = _selectedAiDifficulty == level;

    return InkWell(
      onTap: () => setState(() => _selectedAiDifficulty = level),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.borderGlow,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                  color: isSelected ? color : AppColors.textMuted,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: AppTypography.codeSmall.copyWith(color: AppColors.textSecondary, height: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateRoomPanel(Color teamColor) {
    return Container(
      key: const ValueKey('create_room_panel'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wifi_tethering_rounded, color: AppColors.blueTeam, size: 24),
              const SizedBox(width: 10),
              Text('CRIAR SALA MULTIPLAYER (HOST)', style: AppTypography.titleMedium),
              const Spacer(),
              // Alternador 1v1 ou 2v2
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderGlow),
                ),
                child: Row(
                  children: [
                    _buildModeToggleItem(label: '1v1 Duelo', active: !_is2v2, onTap: () => setState(() => _is2v2 = false)),
                    _buildModeToggleItem(label: '2v2 Duplas', active: _is2v2, onTap: () => setState(() => _is2v2 = true)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Código da Sala
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cardSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.borderGlow),
            ),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CÓDIGO DE CONVITE DA SALA:', style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(
                      _generatedRoomCode,
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.blueTeam,
                        letterSpacing: 4,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: 'Copiar Código',
                  icon: const Icon(Icons.copy_rounded, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: _generatedRoomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Código $_generatedRoomCode copiado para a área de transferência!'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Gerar Novo Código',
                  icon: const Icon(Icons.refresh_rounded, size: 20),
                  onPressed: _regenerateRoomCode,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Slots de Jogadores
          Text('SLOTS DE JOGADORES NA SALA:', style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPlayerSlotCard(
                  slotNumber: 1,
                  teamLabel: 'TIME 1 (AZUL)',
                  teamColor: AppColors.blueTeam,
                  playerName: 'Você (Host)',
                  isHost: true,
                  isReady: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPlayerSlotCard(
                  slotNumber: 2,
                  teamLabel: _is2v2 ? 'TIME 1 (AZUL)' : 'TIME 2 (VERMELHO)',
                  teamColor: _is2v2 ? AppColors.blueTeam : AppColors.redTeam,
                  playerName: 'Aguardando jogador...',
                  isHost: false,
                  isReady: false,
                ),
              ),
              if (_is2v2) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlayerSlotCard(
                    slotNumber: 3,
                    teamLabel: 'TIME 2 (VERMELHO)',
                    teamColor: AppColors.redTeam,
                    playerName: 'Aguardando oponente...',
                    isHost: false,
                    isReady: false,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPlayerSlotCard(
                    slotNumber: 4,
                    teamLabel: 'TIME 2 (VERMELHO)',
                    teamColor: AppColors.redTeam,
                    playerName: 'Aguardando oponente...',
                    isHost: false,
                    isReady: false,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 32),

          // Botão Iniciar Partida
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blueTeam,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              icon: const Icon(Icons.rocket_launch_rounded, size: 26),
              label: Text(
                'LANÇAR SESSÃO MULTIPLAYER',
                style: AppTypography.titleMedium.copyWith(color: Colors.black, fontWeight: FontWeight.bold),
              ),
              onPressed: () => _launchMatch(matchType: 'MULTIPLAYER_HOST', roomCode: _generatedRoomCode),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeToggleItem({required String label, required bool active, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.blueTeam.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: active ? AppColors.blueTeam : AppColors.textMuted,
            fontWeight: active ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerSlotCard({
    required int slotNumber,
    required String teamLabel,
    required Color teamColor,
    required String playerName,
    required bool isHost,
    required bool isReady,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isReady ? teamColor : AppColors.borderGlow,
          width: isReady ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isReady ? AppColors.blueTeam : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                teamLabel,
                style: AppTypography.codeSmall.copyWith(color: teamColor, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                isReady ? Icons.account_circle_rounded : Icons.pending_rounded,
                color: isReady ? Colors.white : AppColors.textMuted,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  playerName,
                  style: AppTypography.bodySmall.copyWith(
                    color: isReady ? Colors.white : AppColors.textMuted,
                    fontWeight: isReady ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFindRoomPanel(Color teamColor) {
    return Container(
      key: const ValueKey('find_room_panel'),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGlow),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore_rounded, color: AppColors.tokensLumber, size: 24),
              const SizedBox(width: 10),
              Text('ENCONTRAR SALA MULTIPLAYER', style: AppTypography.titleMedium),
            ],
          ),
          const SizedBox(height: 16),

          // Campo de busca por código
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _roomCodeInputController,
                  style: AppTypography.bodyMedium.copyWith(color: Colors.white, letterSpacing: 2),
                  decoration: InputDecoration(
                    hintText: 'DIGITE O CÓDIGO DA SALA (EX: CYB-709)',
                    hintStyle: AppTypography.codeSmall.copyWith(color: AppColors.textMuted),
                    filled: true,
                    fillColor: AppColors.cardSurface,
                    prefixIcon: const Icon(Icons.key_rounded, color: AppColors.tokensLumber, size: 20),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.borderGlow),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.tokensLumber, width: 2),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.tokensLumber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('ENTRAR'),
                  onPressed: () {
                    final code = _roomCodeInputController.text.trim();
                    if (code.isNotEmpty) {
                      _launchMatch(matchType: 'JOIN_CODE', roomCode: code);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Lista de Salas Públicas Ativas
          Row(
            children: [
              Text('SALAS PÚBLICAS EM AGUARDO:', style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted)),
              const Spacer(),
              Text('${_publicRooms.length} ATIVAS', style: AppTypography.codeSmall.copyWith(color: AppColors.tokensLumber)),
            ],
          ),
          const SizedBox(height: 12),

          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _publicRooms.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final room = _publicRooms[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderGlow),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.tokensLumber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.tokensLumber),
                      ),
                      child: Text(
                        room.code,
                        style: AppTypography.codeSmall.copyWith(color: AppColors.tokensLumber, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Host: ${room.host}', style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                        Text(room.mode, style: AppTypography.codeSmall.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
                    const Spacer(),
                    // Ping
                    Row(
                      children: [
                        const Icon(Icons.network_check_rounded, color: AppColors.blueTeam, size: 16),
                        const SizedBox(width: 4),
                        Text('${room.ping}ms', style: AppTypography.codeSmall.copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(width: 20),
                    // Slots
                    Text(
                      '${room.players}/${room.maxPlayers} Jogadores',
                      style: AppTypography.codeSmall.copyWith(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.tokensLumber,
                        side: const BorderSide(color: AppColors.tokensLumber),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _launchMatch(matchType: 'JOIN_PUBLIC', roomCode: room.code),
                      child: const Text('ENTRAR'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
