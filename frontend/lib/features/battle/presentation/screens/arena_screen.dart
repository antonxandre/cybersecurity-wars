import 'dart:async';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/cyber_arena_game.dart';
import '../../../auth/domain/services/auth_service.dart';
import '../../domain/models/bastion_node.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/team_player_model.dart';
import '../../domain/models/tactical_unit_info.dart';
import '../../domain/models/tactical_virus_model.dart';
import '../../domain/services/arena_socket_service.dart';
import '../viewmodels/battle_view_model.dart';
import '../widgets/arena_atmosphere_overlay.dart';
import '../widgets/match_header_widget.dart';
import '../widgets/match_phase_banner_overlay.dart';
import '../widgets/match_result_overlay.dart';
import '../widgets/node_context_popup.dart';
import '../widgets/tactical_notification_toast.dart';
import '../widgets/tactical_operations_panel.dart';
import '../widgets/tactical_team_chat_widget.dart';
import '../../../lobby/domain/models/lobby_models.dart';
import '../widgets/tactical_unit_info_hud.dart';
import '../widgets/team_resources_panel.dart';
import '../widgets/virus_dispatcher_dock.dart';

/// Tela principal da Arena de Jogo (combinação do Flame Game Canvas e Overlays Flutter).
class ArenaScreen extends StatefulWidget {
  final String? matchId;
  final dynamic initialExtra;
  const ArenaScreen({super.key, this.matchId, this.initialExtra});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final BattleViewModel _viewModel;
  late final CyberArenaGame _game;
  final GlobalKey<TacticalTeamChatWidgetState> _chatKey =
      GlobalKey<TacticalTeamChatWidgetState>();

  ArenaSocketService? _arenaSocket;
  StreamSubscription? _virusSub;
  StreamSubscription? _chatSub;
  StreamSubscription? _tacticalSub;
  StreamSubscription? _stateSub;

  BoardQuadrant _localQuadrant = BoardQuadrant.topLeft;
  int _localSlot = 0;
  bool _isGameInitialized = false;

  int? _selectedGridX;
  int? _selectedGridY;
  TacticalUnitInfo? _selectedUnit;
  Vector2? _selectedUnitWorldPos;
  TacticalPanelTab? _activeTacticalTab;

  TacticalNotificationItem? _activeNotification;
  Timer? _toastTimer;

  void _resolveLocalSlotAndQuadrant(dynamic matchOrRoomData) {
    if (matchOrRoomData == null) return;
    final currentUser = AuthService.instance.currentUser;
    final myUsername = currentUser?.username;

    // Se matchOrRoomData for um PublicRoom
    if (matchOrRoomData is PublicRoom) {
      final isHost = (myUsername != null &&
              matchOrRoomData.host.toLowerCase() == myUsername.toLowerCase()) ||
          (matchOrRoomData.playerNames.isNotEmpty &&
              myUsername != null &&
              matchOrRoomData.playerNames.first.toLowerCase() == myUsername.toLowerCase());
      final slot = isHost ? 0 : 1;
      _applySlotAndQuadrant(slot, matchOrRoomData.playerNames);
      return;
    }

    if (matchOrRoomData is Map) {
      final bluePlayers = matchOrRoomData['bluePlayers'];
      final redPlayers = matchOrRoomData['redPlayers'];

      if (bluePlayers is List && bluePlayers.isNotEmpty) {
        final names = bluePlayers
            .map((p) => p is Map ? p['username']?.toString() ?? '' : p.toString())
            .toList();
        final idx = myUsername != null
            ? names.indexWhere((n) => n.toLowerCase() == myUsername.toLowerCase())
            : -1;
        if (idx != -1) {
          _applySlotAndQuadrant(idx, names, isBlue: true);
          return;
        }
      }

      if (redPlayers is List && redPlayers.isNotEmpty) {
        final names = redPlayers
            .map((p) => p is Map ? p['username']?.toString() ?? '' : p.toString())
            .toList();
        final idx = myUsername != null
            ? names.indexWhere((n) => n.toLowerCase() == myUsername.toLowerCase())
            : -1;
        if (idx != -1) {
          _applySlotAndQuadrant(idx, names, isBlue: false);
          return;
        }
      }

      final playerNames = matchOrRoomData['playerNames'] as List?;
      if (playerNames != null && playerNames.isNotEmpty && myUsername != null) {
        final names = playerNames.map((e) => e.toString()).toList();
        final idx = names.indexWhere((n) => n.toLowerCase() == myUsername.toLowerCase());
        if (idx != -1) {
          _applySlotAndQuadrant(idx, names);
          return;
        }
      }

      final host = matchOrRoomData['host']?.toString() ??
          matchOrRoomData['hostUsername']?.toString();
      if (host != null && myUsername != null) {
        final isHost = host.toLowerCase() == myUsername.toLowerCase();
        _applySlotAndQuadrant(isHost ? 0 : 1, [host, if (!isHost) myUsername]);
        return;
      }
    }
  }

  void _applySlotAndQuadrant(int slot, List<String> names, {bool isBlue = true}) {
    final quadrant = isBlue
        ? (slot == 1 ? BoardQuadrant.bottomLeft : BoardQuadrant.topLeft)
        : (slot == 1 ? BoardQuadrant.bottomRight : BoardQuadrant.topRight);

    _localSlot = slot;
    _localQuadrant = quadrant;
    _viewModel.setLocalQuadrant(quadrant);

    if (_isGameInitialized) {
      _game.setLocalQuadrant(quadrant);
    }

    final current = _viewModel.currentState;
    final updatedAllyPlayers = current.allyPlayers.map((p) {
      if (p.quadrant == BoardQuadrant.topLeft && names.isNotEmpty) {
        return p.copyWith(name: names[0]);
      } else if (p.quadrant == BoardQuadrant.bottomLeft && names.length > 1) {
        return p.copyWith(name: names[1]);
      }
      return p;
    }).toList();

    _viewModel.updateState(current.copyWith(allyPlayers: updatedAllyPlayers));
    if (_isGameInitialized) {
      _game.updateSectorPlayers(bluePlayers: updatedAllyPlayers);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _viewModel = BattleViewModel();

    _game = CyberArenaGame(
      viewModel: _viewModel,
      onGridCellSelected: _onGridCellSelected,
      localQuadrant: _localQuadrant,
    );
    _isGameInitialized = true;

    final extra = widget.initialExtra;
    if (extra is Map && extra['room'] != null) {
      _resolveLocalSlotAndQuadrant(extra['room']);
    } else if (extra != null) {
      _resolveLocalSlotAndQuadrant(extra);
    }

    // Sincronização remota de rounds e fases (PvP multiplayer)
    _viewModel.onPhaseTransition = (phase, remainingSeconds, currentWave) {
      if (widget.matchId != null && widget.matchId!.isNotEmpty) {
        _arenaSocket?.sendTacticalAction(
          matchId: widget.matchId!,
          type: 'round:phase',
          payload: {
            'phase': phase.name,
            'remainingSeconds': remainingSeconds,
            'currentWave': currentWave,
          },
        );
      }
    };

    // Conexão e sincronização via WebSocket caso seja partida de sala (PvP)
    final matchId = widget.matchId;
    if (matchId != null && matchId.isNotEmpty) {
      _arenaSocket = ArenaSocketService();
      _arenaSocket!.joinMatch(matchId);

      _stateSub = _arenaSocket!.onMatchStateChanged.listen((stateData) {
        if (!mounted) return;
        _resolveLocalSlotAndQuadrant(stateData);
      });

      _virusSub = _arenaSocket!.onOpponentVirusReceived.listen((virus) {
        if (!mounted) return;
        _viewModel.receiveOpponentVirus(virus);
        _showTacticalToast(
          title: 'ATAQUE ADVERSÁRIO',
          message: '${virus.name} recebido na rota!',
          icon: virus.icon,
          accentColor: AppColors.redTeam,
        );
      });

      _chatSub = _arenaSocket!.onChatMessageReceived.listen((msg) {
        if (!mounted) return;
        _viewModel.addExternalChatMessage(msg);
      });

      _tacticalSub = _arenaSocket!.onTacticalActionReceived.listen((action) {
        if (!mounted) return;
        final type = action['type'] as String?;
        final payload = action['payload'];
        if (payload is! Map) return;
        final payloadMap = Map<String, dynamic>.from(payload);

        switch (type) {
          case 'node:build':
          case 'node:upgrade':
            final node = BastionNode.fromJson(payloadMap);
            final quadrantStr = payloadMap['quadrant'] as String?;
            final slot = (payloadMap['slot'] as num?)?.toInt();
            final targetQuadrant = quadrantStr != null
                ? BoardQuadrant.values.firstWhere(
                    (q) => q.name == quadrantStr,
                    orElse: () => BoardQuadrant.topLeft,
                  )
                : (slot == 1 ? BoardQuadrant.bottomLeft : BoardQuadrant.topLeft);

            _viewModel.setQuadrantNode(targetQuadrant, node);
            break;

          case 'node:dismantle':
            final key = payloadMap['key']?.toString();
            final quadrantStr = payloadMap['quadrant'] as String?;
            final slot = (payloadMap['slot'] as num?)?.toInt();
            final targetQuadrant = quadrantStr != null
                ? BoardQuadrant.values.firstWhere(
                    (q) => q.name == quadrantStr,
                    orElse: () => BoardQuadrant.topLeft,
                  )
                : (slot == 1 ? BoardQuadrant.bottomLeft : BoardQuadrant.topLeft);

            if (key != null) {
              _viewModel.removeQuadrantNode(targetQuadrant, key);
            }
            break;

          case 'mainframe:upgrade':
            final target = payloadMap['target']?.toString();
            final stat = payloadMap['stat']?.toString();
            final current = _viewModel.currentState;
            if (target == 'blue') {
              var mf = current.mainframeBlue;
              if (stat == 'cpu') mf = mf.upgradeCpu();
              if (stat == 'ram') mf = mf.upgradeRam();
              if (stat == 'disk') mf = mf.upgradeDisk();
              _viewModel.updateState(current.copyWith(mainframeBlue: mf));
            } else {
              var mf = current.mainframeRed;
              if (stat == 'cpu') mf = mf.upgradeCpu();
              if (stat == 'ram') mf = mf.upgradeRam();
              if (stat == 'disk') mf = mf.upgradeDisk();
              _viewModel.updateState(current.copyWith(mainframeRed: mf));
            }
            break;

          case 'round:phase':
            final phaseName = payloadMap['phase']?.toString();
            final secs = (payloadMap['remainingSeconds'] as num?)?.toInt();
            final wave = (payloadMap['currentWave'] as num?)?.toInt();
            final current = _viewModel.currentState;
            if (phaseName != null) {
              final phase = MatchPhase.values.firstWhere(
                (p) => p.name == phaseName,
                orElse: () => current.phase,
              );
              _viewModel.updateState(current.copyWith(
                phase: phase,
                remainingSeconds: secs ?? current.remainingSeconds,
                currentWave: wave ?? current.currentWave,
              ));
            }
            break;
        }
      });
    }

    // Callback de seleção padronizada de unidades no tabuleiro (Mainframe, Bastião, Malware)
    _game.onTacticalUnitSelected = (unitInfo, worldPos) {
      setState(() {
        _selectedUnit = unitInfo;
        _selectedUnitWorldPos = worldPos;
        _selectedGridX = null;
        _selectedGridY = null;
      });
    };

    // Quando o usuário navega pela câmera (pan ou zoom), re-renderiza o popup/HUD para acompanhar a unidade
    _game.onCameraMoved = () {
      if ((_selectedGridX != null || _selectedUnit != null) && mounted) {
        final binding = WidgetsBinding.instance;
        if (binding.buildOwner?.debugBuilding == true ||
            binding.schedulerPhase == SchedulerPhase.persistentCallbacks) {
          binding.addPostFrameCallback((_) {
            if (mounted && (_selectedGridX != null || _selectedUnit != null)) {
              setState(() {});
            }
          });
        } else {
          setState(() {});
        }
      }
    };

    _viewModel.state.addListener(_handleStateChange);
  }

  void _onGridCellSelected(int gridX, int gridY) {
    final key = '$gridX,$gridY';
    final existingNode = _viewModel.getQuadrantNodes(_localQuadrant)[key] ??
        _viewModel.state.value.nodes[key];
    final isPrepPhase = _viewModel.state.value.phase == MatchPhase.preparation;

    if (existingNode != null) {
      // Célula ocupada: exibe a TacticalUnitInfoHud padronizada com upgrades de nível
      final worldPos = _game.getCellWorldPosition(gridX, gridY);
      setState(() {
        _selectedGridX = null;
        _selectedGridY = null;
        _selectedUnit = TacticalUnitInfo.fromBastionNode(
          node: existingNode,
          gridX: gridX,
          gridY: gridY,
          isPrepPhase: isPrepPhase,
          availableTokens: _viewModel.state.value.economy.tokens,
          onUpgrade: () {
            final upgraded = existingNode.upgrade();
            if (_viewModel.upgradeBastionNode(existingNode)) {
              if (widget.matchId != null && widget.matchId!.isNotEmpty) {
                _arenaSocket?.sendTacticalAction(
                  matchId: widget.matchId!,
                  type: 'node:upgrade',
                  payload: {
                    ...upgraded.toJson(),
                    'quadrant': _localQuadrant.name,
                    'slot': _localSlot,
                  },
                );
              }
            }
          },
          onDismantle: () {
            _viewModel.dismantleNode(existingNode);
            if (widget.matchId != null && widget.matchId!.isNotEmpty) {
              _arenaSocket?.sendTacticalAction(
                matchId: widget.matchId!,
                type: 'node:dismantle',
                payload: {
                  'key': '$gridX,$gridY',
                  'id': existingNode.id,
                  'quadrant': _localQuadrant.name,
                  'slot': _localSlot,
                },
              );
            }
            _clearSelection();
          },
        );
        _selectedUnitWorldPos = worldPos;
      });
    } else {
      // Célula vazia: exibe o menu contextual para alocação de blueprints
      setState(() {
        _selectedGridX = gridX;
        _selectedGridY = gridY;
        _selectedUnit = null;
        _selectedUnitWorldPos = null;
      });
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedGridX = null;
      _selectedGridY = null;
      _selectedUnit = null;
      _selectedUnitWorldPos = null;
    });
    _game.clearGridSelection();
  }

  void _showTacticalToast({
    required String title,
    required String message,
    required IconData icon,
    Color accentColor = AppColors.blueTeam,
  }) {
    _toastTimer?.cancel();
    setState(() {
      _activeNotification = TacticalNotificationItem(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: title,
        message: message,
        icon: icon,
        accentColor: accentColor,
      );
    });
    _toastTimer = Timer(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _activeNotification = null;
        });
      }
    });
  }

  void _tryDispatchVirusByShortcut(int index) {
    if (_chatKey.currentState?.isExpanded == true) return;
    final catalog = TacticalVirusModel.catalog;
    if (index >= 0 && index < catalog.length) {
      final virus = catalog[index];
      final state = _viewModel.state.value;
      if (state.economy.bits >= virus.bitCost) {
        _viewModel.sendTacticalVirus(virus);
        if (widget.matchId != null && widget.matchId!.isNotEmpty) {
          _arenaSocket?.sendVirus(widget.matchId!, virus);
        }
        _showTacticalToast(
          title: 'MALWARE ENVIADO',
          message: '${virus.name} alocado na fila (+${virus.incomeBonus}T/round)',
          icon: virus.icon,
          accentColor: virus.color,
        );
      } else {
        _showTacticalToast(
          title: 'BITS INSUFICIENTES',
          message: '${virus.name} requer ${virus.bitCost} Bits (saldo: ${state.economy.bits})',
          icon: Icons.lock_outline_rounded,
          accentColor: AppColors.redTeam,
        );
      }
    }
  }

  void _recruitMiner() {
    if (_viewModel.recruitMiner()) {
      _showTacticalToast(
        title: 'MINERADOR ATIVADO',
        message: 'Processo minerador online (+5 Bits a cada 3s)',
        icon: Icons.bolt_rounded,
        accentColor: AppColors.bandwidth,
      );
    }
  }

  void _upgradeMainframeCpu(MatchState state) {
    final nextLv = state.mainframeBlue.cpuLevel + 1;
    if (_viewModel.upgradeMainframeCpu(isBlue: true)) {
      _viewModel.sendSystemMessage(
        '[MAINFRAME] Upgrade realizado: OVERCLOCK DE CPU (Lv. $nextLv)',
      );
      if (widget.matchId != null && widget.matchId!.isNotEmpty) {
        _arenaSocket?.sendTacticalAction(
          matchId: widget.matchId!,
          type: 'mainframe:upgrade',
          payload: {'target': 'blue', 'stat': 'cpu'},
        );
      }
    }
  }

  void _upgradeMainframeRam(MatchState state) {
    final nextLv = state.mainframeBlue.ramLevel + 1;
    if (_viewModel.upgradeMainframeRam(isBlue: true)) {
      _viewModel.sendSystemMessage(
        '[MAINFRAME] Upgrade realizado: EXPANSÃO DE RAM (Lv. $nextLv)',
      );
      if (widget.matchId != null && widget.matchId!.isNotEmpty) {
        _arenaSocket?.sendTacticalAction(
          matchId: widget.matchId!,
          type: 'mainframe:upgrade',
          payload: {'target': 'blue', 'stat': 'ram'},
        );
      }
    }
  }

  void _upgradeMainframeDisk(MatchState state) {
    final nextLv = state.mainframeBlue.diskLevel + 1;
    if (_viewModel.upgradeMainframeDisk(isBlue: true)) {
      _viewModel.sendSystemMessage(
        '[MAINFRAME] Upgrade realizado: BLINDAGEM DE DISCO (Lv. $nextLv)',
      );
      if (widget.matchId != null && widget.matchId!.isNotEmpty) {
        _arenaSocket?.sendTacticalAction(
          matchId: widget.matchId!,
          type: 'mainframe:upgrade',
          payload: {'target': 'blue', 'stat': 'disk'},
        );
      }
    }
  }

  void _handleStateChange() {
    final state = _viewModel.state.value;

    if (state.phase == MatchPhase.victory ||
        state.phase == MatchPhase.defeat) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _clearSelection();
      });
    }
  }

  @override
  void dispose() {
    _virusSub?.cancel();
    _chatSub?.cancel();
    _tacticalSub?.cancel();
    _stateSub?.cancel();
    _arenaSocket?.dispose();
    _toastTimer?.cancel();
    _viewModel.state.removeListener(_handleStateChange);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isChatExpanded = _chatKey.currentState?.isExpanded ?? false;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): () {
          final chat = _chatKey.currentState;
          if (chat != null && chat.isExpanded) {
            chat.submitCurrentMessage();
          } else {
            chat?.openChat(channel: ChatChannel.team);
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter): () {
          final chat = _chatKey.currentState;
          if (chat != null && chat.isExpanded) {
            chat.submitCurrentMessage();
          } else {
            chat?.openChat(channel: ChatChannel.team);
          }
        },
        const SingleActivator(LogicalKeyboardKey.enter, shift: true): () {
          final chat = _chatKey.currentState;
          if (chat != null && chat.isExpanded) {
            chat.submitCurrentMessage();
          } else {
            chat?.openChat(channel: ChatChannel.all);
          }
        },
        const SingleActivator(LogicalKeyboardKey.numpadEnter, shift: true): () {
          final chat = _chatKey.currentState;
          if (chat != null && chat.isExpanded) {
            chat.submitCurrentMessage();
          } else {
            chat?.openChat(channel: ChatChannel.all);
          }
        },
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (_chatKey.currentState?.isExpanded == true) {
            _chatKey.currentState?.closeChat();
          } else {
            _clearSelection();
            if (_activeTacticalTab != null) {
              setState(() => _activeTacticalTab = null);
            }
          }
        },
        // Atalhos de teclado [1] a [6] para envio rápido de malwares da fila ofensiva (ativos apenas fora do chat)
        if (!isChatExpanded) ...{
          const SingleActivator(LogicalKeyboardKey.digit1): () => _tryDispatchVirusByShortcut(0),
          const SingleActivator(LogicalKeyboardKey.digit2): () => _tryDispatchVirusByShortcut(1),
          const SingleActivator(LogicalKeyboardKey.digit3): () => _tryDispatchVirusByShortcut(2),
          const SingleActivator(LogicalKeyboardKey.digit4): () => _tryDispatchVirusByShortcut(3),
          const SingleActivator(LogicalKeyboardKey.digit5): () => _tryDispatchVirusByShortcut(4),
          const SingleActivator(LogicalKeyboardKey.digit6): () => _tryDispatchVirusByShortcut(5),
        },
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: ValueListenableBuilder<MatchState>(
            valueListenable: _viewModel.state,
            builder: (context, state, child) {
              final isCriticalAlert = state.mainframeBlue.hpPercentage <= 30.0;
              final screenSize = MediaQuery.of(context).size;
              // Margem inferior responsiva: 10% da altura da tela com piso de segurança de 156px
              // para garantir que o chat nunca fique por baixo do VirusDispatcherDock (~148px)
              final chatBottomMargin =
                  (screenSize.height * 0.10).clamp(156.0, double.infinity);

              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Camada Inferior: Canvas do Jogo 2D Panorâmico (Flame Engine)
                  GameWidget(game: _game),

                  // 2. Camada de Atmosfera Tática (Vinheta radial, scanlines CRT e alerta crítico pulsante)
                  ArenaAtmosphereOverlay(isCriticalAlert: isCriticalAlert),

                  // 3. HUD de Cabeçalho: Placar Central MOBA / Esports
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: MatchHeaderWidget(
                      state: state,
                      onUndoBuild: () => _viewModel.undoBuild(),
                      onReadyPressed: () => _viewModel.startBattlePhase(),
                    ),
                  ),


                  // 5. Painel de Recursos dos Aliados da Rede (Direita)
                  Positioned(
                    top: 98,
                    right: 16,
                    child: TeamResourcesPanel(
                      players: state.allyPlayers,
                      onFocusSector: (quadrant) => _game.focusOnSector(quadrant),
                    ),
                  ),

                  // 6. Painel Unificado de Operações Táticas (Minerador, Fila Ofensiva e Mainframe)
                  if (_activeTacticalTab != null)
                    Positioned(
                      bottom: chatBottomMargin,
                      right: 16,
                      child: TacticalOperationsPanel(
                        activeTab: _activeTacticalTab!,
                        onTabChanged: (tab) => setState(() => _activeTacticalTab = tab),
                        onClose: () => setState(() => _activeTacticalTab = null),
                        economy: state.economy,
                        queuedAttacks: state.queuedAttacksNextRound,
                        mainframe: state.mainframeBlue,
                        onRecruitMiner: _recruitMiner,
                        onUpgradeMainframeCpu: () => _upgradeMainframeCpu(state),
                        onUpgradeMainframeRam: () => _upgradeMainframeRam(state),
                        onUpgradeMainframeDisk: () => _upgradeMainframeDisk(state),
                      ),
                    ),

                  // 7. Toast Tático Flutuante (substitui a SnackBar sem sobrepor o dock)
                  Positioned(
                    bottom: chatBottomMargin,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: TacticalNotificationToast(
                        notification: _activeNotification,
                        onDismiss: () => setState(() => _activeNotification = null),
                      ),
                    ),
                  ),

                  // 8. Dock Tático Inferior: Despacho de Vírus, Mineradores e Mainframe
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: VirusDispatcherDock(
                      economy: state.economy,
                      queuedAttacksCount: state.queuedAttacksNextRound.length,
                      activeTab: _activeTacticalTab,
                      onSendVirus: (virus) {
                        _viewModel.sendTacticalVirus(virus);
                        _showTacticalToast(
                          title: 'MALWARE ENVIADO',
                          message: '${virus.name} na fila! (+${virus.incomeBonus}T no Round ${state.currentWave + 1})',
                          icon: virus.icon,
                          accentColor: virus.color,
                        );
                      },
                      onOpenMinerHub: () => setState(() {
                        _activeTacticalTab = _activeTacticalTab == TacticalPanelTab.miner
                            ? null
                            : TacticalPanelTab.miner;
                      }),
                      onOpenQueuedAttacks: () => setState(() {
                        _activeTacticalTab = _activeTacticalTab == TacticalPanelTab.offensiveQueue
                            ? null
                            : TacticalPanelTab.offensiveQueue;
                      }),
                      onOpenMainframeUpgrades: () => setState(() {
                        _activeTacticalTab = _activeTacticalTab == TacticalPanelTab.mainframe
                            ? null
                            : TacticalPanelTab.mainframe;
                      }),
                    ),
                  ),

                  // 9. Chat Tático de Equipe e Global (posicionado acima do dock e com sobreposição segura)
                  Positioned(
                    bottom: chatBottomMargin,
                    left: 16,
                    child: TacticalTeamChatWidget(
                      key: _chatKey,
                      messages: state.chatMessages,
                      onExpandChanged: () {
                        if (mounted) setState(() {});
                      },
                      onSendMessage: (text, channel) {
                        final currentUser = AuthService.instance.currentUser;
                        final senderName = currentUser?.username ?? 'Operador';
                        _viewModel.sendChatMessage(
                          text: text,
                          channel: channel,
                          senderName: senderName,
                        );
                        if (widget.matchId != null && widget.matchId!.isNotEmpty) {
                          _arenaSocket?.sendChatMessage(
                            matchId: widget.matchId!,
                            text: text,
                            channel: channel,
                            senderName: senderName,
                            senderTeam: currentUser?.isBlueTeam == true ? 'blue' : 'red',
                          );
                        }
                      },
                    ),
                  ),

                  // 10. Pop-up Contextual Holográfico de Célula Vazia (Alocação de Blueprints)
                  if (_selectedGridX != null && _selectedGridY != null) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _clearSelection,
                      ),
                    ),
                    _buildNodePopup(context, state, _selectedGridX!, _selectedGridY!),
                  ],

                  // 11. HUD Display Info Padronizada de Unidade (Mainframe, Bastião, Malware)
                  if (_selectedUnit != null && _selectedUnitWorldPos != null) ...[
                    Positioned.fill(
                      child: GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: _clearSelection,
                      ),
                    ),
                    _buildTacticalUnitHud(context, state, _selectedUnit!, _selectedUnitWorldPos!),
                  ],

                  // 12. Banner Holográfico de Transição de Fase e Onda (Centro da Tela)
                  MatchPhaseBannerOverlay(
                    phase: state.phase,
                    currentWave: state.currentWave,
                    totalWaves: state.totalWaves,
                  ),

                  // 13. Overlay de Fim de Partida (Vitória ou Derrota)
                  if (state.phase == MatchPhase.victory ||
                      state.phase == MatchPhase.defeat)
                    Positioned.fill(
                      child: MatchResultOverlay(
                        state: state,
                        onBackToLobby: () {
                          context.go('/lobby');
                        },
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNodePopup(BuildContext context, MatchState state, int gridX, int gridY) {
    final screenPos = _game.getCellScreenPosition(gridX, gridY);

    final key = '$gridX,$gridY';
    final existingNode = _viewModel.getQuadrantNodes(_localQuadrant)[key] ?? state.nodes[key];
    final isPrepPhase = state.phase == MatchPhase.preparation;

    final screenSize = MediaQuery.of(context).size;
    const popupWidth = 340.0;
    final estimatedHeight = existingNode != null ? 245.0 : 260.0;

    // Calcula posição horizontal centrada na unidade e grampeada na tela
    double left = screenPos.x - (popupWidth / 2);
    left = left.clamp(12.0, (screenSize.width - popupWidth - 12.0).clamp(12.0, double.infinity));

    // Calcula posição vertical (preferencialmente acima da unidade)
    final topAbove = screenPos.y - estimatedHeight - 16.0;
    final bool isAboveUnit = topAbove >= 95.0;
    double top = isAboveUnit ? topAbove : screenPos.y + 36.0;
    top = top.clamp(85.0, (screenSize.height - 130.0 - estimatedHeight).clamp(85.0, double.infinity));

    final double arrowOffset = (screenPos.x - left).clamp(24.0, popupWidth - 24.0);

    return Positioned(
      left: left,
      top: top,
      child: NodeContextPopup(
        gridX: gridX,
        gridY: gridY,
        currentTokens: state.economy.tokens,
        existingNode: existingNode,
        isPrepPhase: isPrepPhase,
        isAboveUnit: isAboveUnit,
        arrowOffset: arrowOffset,
        onNodeSelected: (node) {
          _viewModel.buildNode(node);
          if (widget.matchId != null && widget.matchId!.isNotEmpty) {
            _arenaSocket?.sendTacticalAction(
              matchId: widget.matchId!,
              type: 'node:build',
              payload: {
                ...node.toJson(),
                'quadrant': _localQuadrant.name,
                'slot': _localSlot,
              },
            );
          }
          _clearSelection();
        },
        onNodeDismantled: () {
          if (existingNode != null) {
            _viewModel.dismantleNode(existingNode);
            if (widget.matchId != null && widget.matchId!.isNotEmpty) {
              _arenaSocket?.sendTacticalAction(
                matchId: widget.matchId!,
                type: 'node:dismantle',
                payload: {
                  'key': '$gridX,$gridY',
                  'id': existingNode.id,
                  'quadrant': _localQuadrant.name,
                  'slot': _localSlot,
                },
              );
            }
          }
          _clearSelection();
        },
        onClose: _clearSelection,
      ),
    );
  }

  /// Retorna as informações mais recentes da unidade de acordo com o estado reativo da partida
  TacticalUnitInfo _getFreshUnitInfo(TacticalUnitInfo current, MatchState state) {
    if (current.id == 'mainframe_team_blue') {
      return TacticalUnitInfo.fromMainframe(
        mainframe: state.mainframeBlue,
        isBlue: true,
        availableTokens: state.economy.tokens,
        onUpgradeCpu: () => _viewModel.upgradeMainframeCpu(isBlue: true),
        onUpgradeRam: () => _viewModel.upgradeMainframeRam(isBlue: true),
        onUpgradeDisk: () => _viewModel.upgradeMainframeDisk(isBlue: true),
        onSendChatMessage: (msg) => _viewModel.sendSystemMessage(msg),
        onOpenUpgrades: () {
          _clearSelection();
          setState(() => _activeTacticalTab = TacticalPanelTab.mainframe);
        },
      );
    } else if (current.id == 'mainframe_team_red') {
      return TacticalUnitInfo.fromMainframe(
        mainframe: state.mainframeRed,
        isBlue: false,
      );
    } else if (current.unitType == TacticalUnitType.bastionNode) {
      final parts = current.id.split('_');
      if (parts.length >= 3) {
        final gx = int.tryParse(parts[1]);
        final gy = int.tryParse(parts[2]);
        if (gx != null && gy != null) {
          final key = '$gx,$gy';
          final node = _viewModel.getQuadrantNodes(_localQuadrant)[key] ?? state.nodes[key];
          if (node != null) {
            final isPrepPhase = state.phase == MatchPhase.preparation;
            return TacticalUnitInfo.fromBastionNode(
              node: node,
              gridX: gx,
              gridY: gy,
              isPrepPhase: isPrepPhase,
              availableTokens: state.economy.tokens,
              onUpgrade: () {
                final upgraded = node.upgrade();
                if (_viewModel.upgradeBastionNode(node)) {
                  if (widget.matchId != null && widget.matchId!.isNotEmpty) {
                    _arenaSocket?.sendTacticalAction(
                      matchId: widget.matchId!,
                      type: 'node:upgrade',
                      payload: {
                        ...upgraded.toJson(),
                        'quadrant': _localQuadrant.name,
                        'slot': _localSlot,
                      },
                    );
                  }
                }
              },
              onDismantle: () {
                _viewModel.dismantleNode(node);
                if (widget.matchId != null && widget.matchId!.isNotEmpty) {
                  _arenaSocket?.sendTacticalAction(
                    matchId: widget.matchId!,
                    type: 'node:dismantle',
                    payload: {
                      'key': '$gx,$gy',
                      'id': node.id,
                      'quadrant': _localQuadrant.name,
                      'slot': _localSlot,
                    },
                  );
                }
                _clearSelection();
              },
            );
          }
        }
      }
    }
    return current;
  }

  /// Constrói a HUD de status posicionada sobre a unidade com grampeamento de tela e rastreamento de câmera
  Widget _buildTacticalUnitHud(
    BuildContext context,
    MatchState state,
    TacticalUnitInfo unit,
    Vector2 worldPos,
  ) {
    final freshUnit = _getFreshUnitInfo(unit, state);
    final screenPos = _game.getWorldScreenPosition(worldPos);

    final screenSize = MediaQuery.of(context).size;
    const hudWidth = 360.0;
    final int upgradesCount = freshUnit.upgrades.length;
    final double estimatedHeight = 240.0 +
        (upgradesCount * 62.0) +
        (freshUnit.onPrimaryAction != null ? 52.0 : 0.0) +
        (freshUnit.currentEffect != null ? 110.0 : 0.0);

    // Calcula posição horizontal centrada na unidade e grampeada na tela com margem segura
    double left = screenPos.x - (hudWidth / 2);
    left = left.clamp(12.0, (screenSize.width - hudWidth - 12.0).clamp(12.0, double.infinity));

    // Calcula posição vertical (preferencialmente acima da unidade)
    final topAbove = screenPos.y - estimatedHeight - 16.0;
    final bool isAboveUnit = topAbove >= 95.0;
    double top = isAboveUnit ? topAbove : screenPos.y + 40.0;
    top = top.clamp(85.0, (screenSize.height - 130.0 - estimatedHeight).clamp(85.0, double.infinity));

    final double arrowOffset = (screenPos.x - left).clamp(24.0, hudWidth - 24.0);

    return Positioned(
      left: left,
      top: top,
      child: TacticalUnitInfoHud(
        info: freshUnit,
        isAboveUnit: isAboveUnit,
        arrowOffset: arrowOffset,
        onClose: _clearSelection,
      ),
    );
  }
}
