import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/cyber_arena_game.dart';
import '../../domain/models/match_state.dart';
import '../../domain/services/scripted_bot_service.dart';
import '../viewmodels/battle_view_model.dart';
import '../widgets/mainframe_upgrade_sheet.dart';
import '../widgets/match_header_widget.dart';
import '../widgets/match_result_overlay.dart';
import '../widgets/node_selection_sheet.dart';
import '../widgets/panoramic_camera_bar.dart';
import '../widgets/perk_selection_dialog.dart';
import '../widgets/virus_dispatcher_dock.dart';

/// Tela principal da Arena de Jogo (combinação do Flame Game Canvas e Overlays Flutter).
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final BattleViewModel _viewModel;
  late final CyberArenaGame _game;
  final ScriptedBotService _botService = ScriptedBotService();
  bool _isPerkDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _viewModel = BattleViewModel();
    _game = CyberArenaGame(
      viewModel: _viewModel,
      onGridCellSelected: _onGridCellSelected,
    );

    _viewModel.state.addListener(_handleStateChange);

    // Turno inicial da IA no Campo 2 (Oponente)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeBotTurn();
    });
  }

  void _executeBotTurn() {
    final state = _viewModel.state.value;
    final botTurn = _botService.executeWaveTurn(state.currentWave, state.opponentNodes);

    if (botTurn.newOpponentNodes != state.opponentNodes ||
        botTurn.upgradeCpu ||
        botTurn.upgradeRam ||
        botTurn.upgradeDisk) {
      var nextState = state.copyWith(opponentNodes: botTurn.newOpponentNodes);
      if (botTurn.upgradeCpu) {
        nextState = nextState.copyWith(mainframeRed: nextState.mainframeRed.upgradeCpu());
      }
      if (botTurn.upgradeRam) {
        nextState = nextState.copyWith(mainframeRed: nextState.mainframeRed.upgradeRam());
      }
      if (botTurn.upgradeDisk) {
        nextState = nextState.copyWith(mainframeRed: nextState.mainframeRed.upgradeDisk());
      }
      _viewModel.updateState(nextState);
    }
  }

  void _onGridCellSelected(int gridX, int gridY) {
    final state = _viewModel.state.value;

    if (state.phase != MatchPhase.preparation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Construção de bastiões bloqueada durante o combate ativo!'),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.cardSurface,
        ),
      );
      _game.clearGridSelection();
      return;
    }

    final key = '$gridX,$gridY';
    final existingNode = state.nodes[key];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return NodeSelectionSheet(
          gridX: gridX,
          gridY: gridY,
          existingNode: existingNode,
          currentCpu: state.cpuBudget,
          onNodeSelected: (node) {
            _viewModel.buildNode(node);
            _game.clearGridSelection();
          },
          onNodeDismantled: () {
            if (existingNode != null) {
              _viewModel.dismantleNode(existingNode);
            }
            _game.clearGridSelection();
          },
        );
      },
    ).whenComplete(() {
      _game.clearGridSelection();
    });
  }

  void _showMainframeUpgradeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return ValueListenableBuilder<MatchState>(
          valueListenable: _viewModel.state,
          builder: (context, state, _) {
            return MainframeUpgradeSheet(
              mainframe: state.mainframeBlue,
              availableTokens: state.economy.tokens,
              onUpgradeCpu: () => _viewModel.upgradeMainframeCpu(isBlue: true),
              onUpgradeRam: () => _viewModel.upgradeMainframeRam(isBlue: true),
              onUpgradeDisk: () => _viewModel.upgradeMainframeDisk(isBlue: true),
            );
          },
        );
      },
    );
  }

  void _handleStateChange() {
    final state = _viewModel.state.value;

    if (state.phase == MatchPhase.preparation) {
      _executeBotTurn();
    }

    if (state.phase == MatchPhase.perkDraft && !_isPerkDialogShowing && state.draftOptions.isNotEmpty) {
      _isPerkDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => PerkSelectionDialog(
            perks: state.draftOptions,
            onPerkSelected: (perk) {
              Navigator.pop(ctx);
              _isPerkDialogShowing = false;
              _viewModel.selectPerk(perk);
            },
          ),
        );
      });
    }
  }

  @override
  void dispose() {
    _viewModel.state.removeListener(_handleStateChange);
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: ValueListenableBuilder<MatchState>(
        valueListenable: _viewModel.state,
        builder: (context, state, child) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // 1. Camada Inferior: Canvas do Jogo 2D Panorâmico (Flame Engine)
              GameWidget(game: _game),

              // 2. Camada Superior: HUD de Cabeçalho (Telemetria & SLA)
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

              // 2.1. Barra Flutuante de Controle de Câmera Panorâmica
              Positioned(
                top: 105,
                left: 16,
                child: PanoramicCameraBar(
                  onFocusMyGrid: () => _game.focusOnMyGrid(),
                  onFocusOverview: () => _game.focusOnOverview(),
                  onFocusOpponent: () => _game.focusOnOpponent(),
                  onFocusMainframe: () => _game.focusOnMainframe(true),
                ),
              ),

              // 3. Camada Inferior: Dock Tático de Envio de Vírus e Mineradores (Legion TD)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: VirusDispatcherDock(
                  economy: state.economy,
                  onSendVirus: (virus) {
                    _viewModel.sendTacticalVirus(virus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('MALWARE DESPACHADO: ${virus.name}! (+${virus.incomeBonus} Renda)'),
                        backgroundColor: AppColors.cardSurface,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  onRecruitMiner: () => _viewModel.recruitMiner(),
                  onOpenMainframeUpgrades: () => _showMainframeUpgradeSheet(),
                ),
              ),

              // 4. Overlay de Fim de Partida (Vitória ou Derrota)
              if (state.phase == MatchPhase.victory || state.phase == MatchPhase.defeat)
                Positioned.fill(
                  child: MatchResultOverlay(
                    state: state,
                    onPlayAgain: () {
                      _botService.reset();
                      _viewModel.resetMatch();
                      _game.resetGame();
                      _executeBotTurn();
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
