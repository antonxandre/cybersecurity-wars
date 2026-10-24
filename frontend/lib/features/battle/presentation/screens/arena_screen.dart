import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../game/cyber_arena_game.dart';
import '../../domain/models/match_state.dart';
import '../viewmodels/battle_view_model.dart';
import '../widgets/bandwidth_meter_widget.dart';
import '../widgets/card_dock_widget.dart';
import '../widgets/match_header_widget.dart';
import '../widgets/match_result_overlay.dart';
import '../widgets/node_selection_sheet.dart';
import '../widgets/panoramic_camera_bar.dart';
import '../widgets/perk_selection_dialog.dart';

/// Tela principal da Arena de Jogo (combinação do Flame Game Canvas e Overlays Flutter).
class ArenaScreen extends StatefulWidget {
  const ArenaScreen({super.key});

  @override
  State<ArenaScreen> createState() => _ArenaScreenState();
}

class _ArenaScreenState extends State<ArenaScreen> {
  late final BattleViewModel _viewModel;
  late final CyberArenaGame _game;
  bool _isPerkDialogShowing = false;

  @override
  void initState() {
    super.initState();
    _viewModel = BattleViewModel();
    _game = CyberArenaGame(
      viewModel: _viewModel,
      onGridCellSelected: _onGridCellSelected,
    );

    // Ouve mudanças de estado para abrir o modal de Perks do Archero
    _viewModel.state.addListener(_handleStateChange);
  }

  void _onGridCellSelected(int gridX, int gridY) {
    final state = _viewModel.state.value;

    // Apenas permite alocação/remoção durante a Fase de Preparação (Legion TD)
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
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => NodeSelectionSheet(
        gridX: gridX,
        gridY: gridY,
        currentCpu: state.cpuBudget,
        existingNode: existingNode,
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
      ),
    ).then((_) {
      _game.clearGridSelection();
    });
  }

  void _handleStateChange() {
    final state = _viewModel.state.value;
    if (state.phase == MatchPhase.perkDraft && !_isPerkDialogShowing) {
      _isPerkDialogShowing = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      body: Center(
        // Mantém proporção mobile tática elegante em qualquer dispositivo/navegador
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ValueListenableBuilder<MatchState>(
            valueListenable: _viewModel.state,
            builder: (context, state, child) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  // 1. Camada Inferior: Canvas do Jogo 2D (Flame Engine)
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

                  // 3. Camada Inferior: Barra de Energia e Dock de Cartas (Clash Royale)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Barra de Banda de Rede (Energia / Mana)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: BandwidthMeterWidget(
                            bandwidth: state.bandwidth,
                            maxBandwidth: state.maxBandwidth,
                          ),
                        ),
                        // Dock de 4 Cartas Táticas
                        CardDockWidget(
                          hand: state.hand,
                          currentBandwidth: state.bandwidth,
                          onCardPlay: (card, lane) {
                            _viewModel.deployCard(card, lane);
                          },
                        ),
                      ],
                    ),
                  ),

                  // 4. Overlay de Fim de Partida (Vitória ou Derrota)
                  if (state.phase == MatchPhase.victory || state.phase == MatchPhase.defeat)
                    Positioned.fill(
                      child: MatchResultOverlay(
                        state: state,
                        onPlayAgain: () {
                          _viewModel.resetMatch();
                          _game.resetGame();
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
}
