import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/models/auth_user.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/lobby_models.dart';
import '../viewmodels/lobby_view_model.dart';
import '../widgets/cyber_grid_background.dart';
import '../widgets/friends_party_panel.dart';
import '../widgets/game_mode_hero.dart';
import '../widgets/lobby_mode_rail.dart';
import '../widgets/lobby_top_bar.dart';
import '../widgets/matchmaking_overlay.dart';
import '../widgets/news_panel.dart';
import '../widgets/player_profile_card.dart';
import '../widgets/room_browser_panel.dart';
import '../widgets/waiting_room_view.dart';

/// Tela Principal do Lobby de Jogo com padrão visual Esports AAA (Valorant/League).
class GameLobbyScreen extends StatefulWidget {
  const GameLobbyScreen({super.key});

  @override
  State<GameLobbyScreen> createState() => _GameLobbyScreenState();
}

class _GameLobbyScreenState extends State<GameLobbyScreen> {
  late final LobbyViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = LobbyViewModel();
    _viewModel.onMatchLaunchRequested = (code) => _onLaunchArena(code);
    final currentUser = AuthService.instance.currentUser;
    if (currentUser != null && currentUser.username.isNotEmpty) {
      _viewModel.setHostUsername(currentUser.username);
    }
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _onLaunchArena([String? matchCode]) {
    if (!mounted) return;
    final code = matchCode ?? _viewModel.activeWaitingRoom?.code;
    final extraData = {
      'matchCode': code,
      'room': _viewModel.activeWaitingRoom,
    };
    if (code != null && code.isNotEmpty) {
      context.go('/arena?matchId=$code', extra: extraData);
    } else {
      context.go('/arena', extra: extraData);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;
    final currentUser = authService.currentUser ??
        const AuthUser(
          id: 'usr_ghost',
          username: 'Operador Ghost',
          email: 'operador@promptsec.arena',
          role: UserRole.blueTeam,
        );

    final teamColor = currentUser.isBlueTeam ? AppColors.blueTeam : AppColors.redTeam;

    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final currentMode = _viewModel.currentMode;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              // 1. Fundo Procedural Dinâmico com Partículas e Grade Cyber
              CyberGridBackground(
                accentColor: currentMode.accentColor,
              ),

              // 2. Interface Principal
              SafeArea(
                child: Column(
                  children: [
                    // Barra Superior Institucional
                    LobbyTopBar(
                      teamColor: teamColor,
                    ),

                    // Área Central de Jogo
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth >= 1100) {
                            return _buildDesktopLayout(context, teamColor, currentUser);
                          } else if (constraints.maxWidth >= 768) {
                            return _buildTabletLayout(context, teamColor, currentUser);
                          } else {
                            return _buildMobileLayout(context, teamColor, currentUser);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Overlay Modal de Inicialização de Sala / Simulação
              MatchmakingOverlay(
                phase: _viewModel.matchmakingPhase,
                elapsedSeconds: _viewModel.matchmakingElapsedSeconds,
                countdownSeconds: _viewModel.countdownSeconds,
                onCancel: _viewModel.cancelMatchmaking,
                mode: _viewModel.currentMode,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCenterContent(BuildContext context) {
    if (_viewModel.isInWaitingRoom) {
      return WaitingRoomView(
        room: _viewModel.activeWaitingRoom!,
        onLeaveRoom: _viewModel.leaveWaitingRoom,
        onStartMatch: () {
          _viewModel.triggerStartMatch(onReadyToLaunch: (code) => _onLaunchArena(code));
        },
        onSimulateJoin: _viewModel.simulateJoinSlot,
        onInviteFriend: (friend) {
          _viewModel.inviteFriend(friend);
        },
        availableFriends: _viewModel.friends,
      );
    }

    if (_viewModel.currentMode == LobbyMode.createRoom) {
      return RoomBrowserPanel(
        rooms: _viewModel.publicRooms,
        onJoinRoom: (room) async {
          final joined = await _viewModel.joinRoom(room);
          if (!joined && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Esta sala está lotada! Não é possível entrar.'),
                backgroundColor: AppColors.redTeam,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onJoinByCode: (code) async {
          final success = await _viewModel.joinRoomByCode(code);
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Código inválido ou sala não encontrada / lotada.'),
                backgroundColor: AppColors.redTeam,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        },
        onCreateRoom: () async {
          await _viewModel.createRoom();
        },
        onRefresh: () => _viewModel.refreshPublicRooms(),
      );
    }

    return SingleChildScrollView(
      child: GameModeHero(
        mode: _viewModel.currentMode,
        aiDifficulty: _viewModel.aiDifficulty,
        onDifficultyChanged: _viewModel.setAiDifficulty,
        is2v2: _viewModel.is2v2,
        onToggle2v2: _viewModel.setIs2v2,
        roomCode: _viewModel.generatedRoomCode,
        onRegenerateRoomCode: _viewModel.regenerateRoomCode,
        partyMembers: _viewModel.partyMembers,
        publicRooms: _viewModel.publicRooms,
        onJoinRoom: (code) {
          _viewModel.joinRoomByCode(code);
        },
        onPlayPressed: () {
          _viewModel.startMatchmaking(onReadyToLaunch: _onLaunchArena);
        },
        isSearchingMatch: _viewModel.isSearchingMatch,
      ),
    );
  }

  /// Layout Desktop Widescreen (>= 1100px) estilo Client AAA
  Widget _buildDesktopLayout(BuildContext context, Color teamColor, AuthUser currentUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Rail de Modos à Esquerda
          LobbyModeRail(
            currentMode: _viewModel.currentMode,
            onModeSelected: _viewModel.setMode,
          ),
          const SizedBox(width: 18),

          // Área Central de Navegação / Sala
          Expanded(
            flex: 6,
            child: _buildCenterContent(context),
          ),
          const SizedBox(width: 18),

          // Coluna Direita: Estatísticas do Perfil, Amigos e Notícias
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  PlayerProfileCard(
                    profile: _viewModel.profile,
                    user: currentUser,
                    teamColor: teamColor,
                  ),
                  const SizedBox(height: 14),
                  FriendsPartyPanel(
                    friends: _viewModel.friends,
                    partyMembers: _viewModel.partyMembers,
                    maxSlots: _viewModel.maxPartySlots,
                    onInviteFriend: (friend) {
                      _viewModel.inviteFriend(friend);
                    },
                    onRemovePartyMember: _viewModel.removePartyMember,
                    onAddFriend: _viewModel.addFriend,
                  ),
                  const SizedBox(height: 14),
                  NewsPanel(news: _viewModel.news),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Layout Tablet (768px a 1099px)
  Widget _buildTabletLayout(BuildContext context, Color teamColor, AuthUser currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Seletor horizontal de modos
          LobbyModeRail(
            currentMode: _viewModel.currentMode,
            onModeSelected: _viewModel.setMode,
            isHorizontal: true,
          ),
          const SizedBox(height: 16),

          // Área Central
          SizedBox(
            height: 620,
            child: _buildCenterContent(context),
          ),
          const SizedBox(height: 16),

          // Painéis em linha
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: PlayerProfileCard(
                  profile: _viewModel.profile,
                  user: currentUser,
                  teamColor: teamColor,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: [
                    FriendsPartyPanel(
                      friends: _viewModel.friends,
                      partyMembers: _viewModel.partyMembers,
                      maxSlots: _viewModel.maxPartySlots,
                      onInviteFriend: (friend) {
                        _viewModel.inviteFriend(friend);
                      },
                      onRemovePartyMember: _viewModel.removePartyMember,
                      onAddFriend: _viewModel.addFriend,
                    ),
                    const SizedBox(height: 14),
                    NewsPanel(news: _viewModel.news),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Layout Mobile (< 768px)
  Widget _buildMobileLayout(BuildContext context, Color teamColor, AuthUser currentUser) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          LobbyModeRail(
            currentMode: _viewModel.currentMode,
            onModeSelected: _viewModel.setMode,
            isHorizontal: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 580,
            child: _buildCenterContent(context),
          ),
          const SizedBox(height: 12),
          PlayerProfileCard(
            profile: _viewModel.profile,
            user: currentUser,
            teamColor: teamColor,
          ),
          const SizedBox(height: 12),
          FriendsPartyPanel(
            friends: _viewModel.friends,
            partyMembers: _viewModel.partyMembers,
            maxSlots: _viewModel.maxPartySlots,
            onInviteFriend: (friend) {
              _viewModel.inviteFriend(friend);
            },
            onRemovePartyMember: _viewModel.removePartyMember,
            onAddFriend: _viewModel.addFriend,
          ),
          const SizedBox(height: 12),
          NewsPanel(news: _viewModel.news),
        ],
      ),
    );
  }
}
