import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../../../core/commands/command_executor.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/models/bastion_node.dart';
import '../../domain/models/chat_message.dart';
import '../../domain/models/game_card.dart';
import '../../domain/models/match_state.dart';
import '../../domain/models/tactical_virus_model.dart';
import '../../domain/models/team_player_model.dart';
import '../commands/battle_commands.dart';

/// ViewModel que orquestra a sessão de jogo e a ponte entre a UI e o Flame Engine.
class BattleViewModel extends ChangeNotifier {
  late final CommandExecutor<BattleViewModel> executor;
  final ValueNotifier<MatchState> state = ValueNotifier(MatchState.initial());

  MatchState? _pendingState;
  bool _isDisposed = false;
  bool _isFrameUpdateScheduled = false;

  /// Retorna o estado atualizado mais recente, mesmo que a notificação de frame esteja pendente.
  MatchState get currentState => _pendingState ?? state.value;

  Timer? _bandwidthTimer;
  Timer? _countdownTimer;

  // Stream de eventos despachados para o Flame Game Canvas
  final StreamController<({GameCard card, int lane})> _flameDispatches =
      StreamController.broadcast();
  Stream<({GameCard card, int lane})> get flameDispatches => _flameDispatches.stream;

  BattleViewModel() {
    executor = CommandExecutor(this);
    _initializeInitialDeckAndHand();
    _startTimers();
  }

  void updateState(MatchState newState) {
    if (_isDisposed) return;
    _pendingState = newState;

    void applyUpdate() {
      _isFrameUpdateScheduled = false;
      if (_isDisposed) return;
      if (_pendingState != null) {
        state.value = _pendingState!;
        _pendingState = null;
      }
      notifyListeners();
    }

    WidgetsBinding? binding;
    try {
      binding = WidgetsBinding.instance;
    } catch (_) {
      binding = null;
    }

    // Se o framework estiver no meio de um build/layout (ex: LayoutBuilder do Flame GameWidget),
    // posterga a notificação para o addPostFrameCallback para evitar setState() during build.
    if (binding != null &&
        (binding.buildOwner?.debugBuilding == true ||
            binding.schedulerPhase == SchedulerPhase.persistentCallbacks)) {
      if (!_isFrameUpdateScheduled) {
        _isFrameUpdateScheduled = true;
        binding.addPostFrameCallback((_) {
          applyUpdate();
        });
      }
    } else {
      applyUpdate();
    }
  }

  /// Notifica o Flame Engine sobre cartas jogadas nas rotas de rede
  void onCardDispatchedToFlame(GameCard card, int lane) {
    _flameDispatches.add((card: card, lane: lane));
  }

  /// Constrói um nó no grid (Turno de Preparação / Legion TD)
  Future<bool> buildNode(BastionNode node) async {
    return executor.run(BuildBastionNodeCommand(node));
  }

  /// Desfaz a última alocação de nó com reembolso de CPU
  Future<bool> undoBuild() async {
    return executor.undoLast();
  }

  /// Desmonta um nó específico no grid e reembolsa seu custo de CPU
  Future<bool> dismantleNode(BastionNode node) async {
    return executor.run(DismantleBastionNodeCommand(node));
  }

  /// Realiza a evolução de nível (Level Up 1 -> 2 -> 3) de um nó defensivo gastando Tokens
  bool upgradeBastionNode(BastionNode node) {
    final current = currentState;
    final cost = node.upgradeCost;
    if (cost == null || current.economy.tokens < cost || node.isMaxLevel) {
      return false;
    }

    final key = '${node.gridX},${node.gridY}';
    final upgradedNode = node.upgrade();
    final updatedNodes = Map<String, BastionNode>.from(current.nodes)..[key] = upgradedNode;
    final updatedEconomy = current.economy.spendTokens(cost);

    updateState(current.copyWith(
      economy: updatedEconomy,
      nodes: updatedNodes,
    ));

    sendSystemMessage(
      '[NÓ DEFENSIVO] ${node.name.toUpperCase()} evoluído para NÍVEL ${upgradedNode.level}!',
    );
    return true;
  }

  /// Despacha uma carta na rota selecionada (Clash Royale)
  Future<bool> deployCard(GameCard card, int targetLane) async {
    return executor.run(DeployCardCommand(card: card, targetLane: targetLane));
  }

  /// Inicia a fase de combate em tempo real
  void startBattlePhase() {
    executor.clearHistory();
    updateState(currentState.copyWith(
      phase: MatchPhase.battle,
      remainingSeconds: 60,
    ));
  }

  /// Realiza upgrade de CPU no Mainframe Central
  bool upgradeMainframeCpu({bool isBlue = true}) {
    final current = currentState;
    final mainframe = isBlue ? current.mainframeBlue : current.mainframeRed;
    final cost = mainframe.upgradeCostCpu;

    if (!mainframe.canUpgradeCpu || current.economy.tokens < cost) return false;

    final updatedEconomy = current.economy.spendTokens(cost);
    final updatedMainframe = mainframe.upgradeCpu();

    updateState(current.copyWith(
      economy: updatedEconomy,
      mainframeBlue: isBlue ? updatedMainframe : current.mainframeBlue,
      mainframeRed: !isBlue ? updatedMainframe : current.mainframeRed,
    ));
    return true;
  }

  /// Realiza upgrade de RAM no Mainframe Central (alvos simultâneos)
  bool upgradeMainframeRam({bool isBlue = true}) {
    final current = currentState;
    final mainframe = isBlue ? current.mainframeBlue : current.mainframeRed;
    final cost = mainframe.upgradeCostRam;

    if (!mainframe.canUpgradeRam || current.economy.tokens < cost) return false;

    final updatedEconomy = current.economy.spendTokens(cost);
    final updatedMainframe = mainframe.upgradeRam();

    updateState(current.copyWith(
      economy: updatedEconomy,
      mainframeBlue: isBlue ? updatedMainframe : current.mainframeBlue,
      mainframeRed: !isBlue ? updatedMainframe : current.mainframeRed,
    ));
    return true;
  }

  /// Realiza upgrade de Disco no Mainframe Central (capacidade total e HP)
  bool upgradeMainframeDisk({bool isBlue = true}) {
    final current = currentState;
    final mainframe = isBlue ? current.mainframeBlue : current.mainframeRed;
    final cost = mainframe.upgradeCostDisk;

    if (!mainframe.canUpgradeDisk || current.economy.tokens < cost) return false;

    final updatedEconomy = current.economy.spendTokens(cost);
    final updatedMainframe = mainframe.upgradeDisk();

    updateState(current.copyWith(
      economy: updatedEconomy,
      mainframeBlue: isBlue ? updatedMainframe : current.mainframeBlue,
      mainframeRed: !isBlue ? updatedMainframe : current.mainframeRed,
    ));
    return true;
  }

  /// Recruta um processo minerador de Bits (HashMiner Daemon) gastando Tokens
  bool recruitMiner() {
    final current = currentState;
    if (!current.economy.canRecruitMiner) return false;

    final updatedEconomy = current.economy.recruitMiner();
    updateState(current.copyWith(
      tokens: updatedEconomy.tokens,
      economy: updatedEconomy,
    ));
    return true;
  }

  /// Envia um vírus tático contra o oponente gastando Bits (aumenta a renda permanente de Tokens!)
  bool sendTacticalVirus(TacticalVirusModel virus) {
    final current = currentState;
    if (current.economy.bits < virus.bitCost) return false;

    final updatedEconomy = current.economy.registerAttackSent(
      bitCost: virus.bitCost,
      incomeBonusTokens: virus.incomeBonusTokens,
    );

    final updatedQueue = List<TacticalVirusModel>.from(current.queuedAttacksNextRound)..add(virus);

    updateState(current.copyWith(
      economy: updatedEconomy,
      queuedAttacksNextRound: updatedQueue,
      queuedVirusesForOpponent: updatedQueue,
    ));
    return true;
  }

  /// Adiciona pacote malicioso enviado por oponente remoto via WebSocket na fila de ataque
  void receiveOpponentVirus(TacticalVirusModel virus) {
    final current = currentState;
    final updatedQueue = List<TacticalVirusModel>.from(current.queuedVirusesForOpponent)..add(virus);
    updateState(current.copyWith(
      queuedVirusesForOpponent: updatedQueue,
    ));
  }

  /// Adiciona mensagem de chat recebida via WebSocket remoto evitando duplicações
  void addExternalChatMessage(ChatMessage message) {
    final current = currentState;
    if (current.chatMessages.any((m) => m.id == message.id)) return;
    updateState(current.copyWith(
      chatMessages: [...current.chatMessages, message],
    ));
  }

  /// Dano sofrido pelo Mainframe Central
  void onMainframeDamaged(String teamId, double damage) {
    final current = currentState;
    final isBlue = teamId.contains('blue');
    final target = isBlue ? current.mainframeBlue : current.mainframeRed;
    final damaged = target.receiveDamage(damage);

    if (isBlue) {
      if (damaged.isDestroyed) {
        updateState(current.copyWith(
          mainframeBlue: damaged,
          phase: MatchPhase.defeat,
        ));
      } else {
        updateState(current.copyWith(mainframeBlue: damaged));
      }
    } else {
      if (damaged.isDestroyed) {
        updateState(current.copyWith(
          mainframeRed: damaged,
          phase: MatchPhase.victory,
        ));
      } else {
        updateState(current.copyWith(mainframeRed: damaged));
      }
    }
  }

  /// Retorna a contagem acumulada de unidades que vazaram (leaks)
  int get totalLeaks => currentState.totalLeaks;

  /// Registra vazamento de unidade (leak) além da zona do jogador e atualiza telemetria
  void recordLeak({String teamId = 'team_blue', BoardQuadrant? quadrant}) {
    final current = currentState;
    final updatedAllyPlayers = current.allyPlayers.map((player) {
      if (quadrant != null && player.quadrant == quadrant) {
        return player.copyWith(waveStatus: PlayerWaveStatus.leakingThreats);
      }
      return player;
    }).toList();

    updateState(current.copyWith(
      totalLeaks: current.totalLeaks + 1,
      allyPlayers: updatedAllyPlayers,
    ));
    debugPrint('[BattleVM] Leak registrado! totalLeaks = ${current.totalLeaks + 1} (quadrante: $quadrant)');
  }

  /// Aplica dano ao Mainframe quando um pacote inimigo atinge a base
  void onCoreDamaged(double damage) {
    onMainframeDamaged('team_blue', damage);
  }

  /// Incrementa contador de pacotes invasores neutralizados pelos bastiões
  void onPacketNeutralized() {
    final current = currentState;
    updateState(current.copyWith(
      statsPacketsNeutralized: current.statsPacketsNeutralized + 1,
    ));
  }

  /// Tráfego cliente entregue com sucesso
  void onClientDelivered() {
    // Tráfego cliente entregue com sucesso
  }

  /// Aplica penalidade ao Mainframe quando tráfego crítico falha
  void onSlaPenalized(double penalty) {
    onMainframeDamaged('team_blue', penalty);
  }

  /// Invocado quando uma onda de ataque é vencida com sucesso
  void onWaveVictory(int completedWave) {
    final current = currentState;
    if (completedWave >= current.totalWaves) {
      onMatchVictory();
    } else {
      // Avança a onda, paga a renda de Tokens e retorna à fase de preparação
      final nextWave = completedWave + 1;
      final updatedEconomy = current.economy.applyRoundIncome();
      updateState(current.copyWith(
        currentWave: nextWave,
        phase: MatchPhase.preparation,
        remainingSeconds: 35,
        tokens: updatedEconomy.tokens,
        economy: updatedEconomy,
        queuedAttacksNextRound: [],
      ));
      debugPrint('[BattleVM] Onda $completedWave superada! Retornando à preparação. Renda de Tokens paga: ${updatedEconomy.totalIncomeTokens}');
    }
  }

  /// Declara vitória definitiva da partida (todas as ondas superadas)
  void onMatchVictory() {
    final current = currentState;
    updateState(current.copyWith(phase: MatchPhase.victory));
    sendSystemMessage('🏆 VITÓRIA DO CLUSTER! Todas as ameaças foram neutralizadas!');
    debugPrint('[BattleVM] VITÓRIA! Todas as ondas foram neutralizadas com sucesso!');
  }

  /// Envia mensagem de chat da equipe ou global (estilo Warcraft 3 / League of Legends)
  void sendChatMessage({
    required String text,
    ChatChannel channel = ChatChannel.team,
    String? senderId,
    String? senderName,
    Color? senderColor,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    ChatChannel targetChannel = channel;
    String cleanText = trimmed;

    // Detecção inteligente de comandos de canal (/all, /todos, /a ou /team, /equipe, /t)
    final lower = trimmed.toLowerCase();
    if (lower.startsWith('/all ') || lower.startsWith('/todos ') || lower.startsWith('/a ')) {
      targetChannel = ChatChannel.all;
      final spaceIdx = trimmed.indexOf(' ');
      cleanText = trimmed.substring(spaceIdx + 1).trim();
    } else if (lower.startsWith('/team ') || lower.startsWith('/equipe ') || lower.startsWith('/t ')) {
      targetChannel = ChatChannel.team;
      final spaceIdx = trimmed.indexOf(' ');
      cleanText = trimmed.substring(spaceIdx + 1).trim();
    }

    if (cleanText.isEmpty) return;

    final current = currentState;
    final localPlayer = current.allyPlayers.isNotEmpty ? current.allyPlayers.first : null;

    final message = ChatMessage.player(
      senderId: senderId ?? localPlayer?.id ?? 'player_blue_1',
      senderName: senderName ?? localPlayer?.name ?? 'Jogador 1 (Você)',
      senderColor: senderColor ?? localPlayer?.color ?? AppColors.blueTeam,
      channel: targetChannel,
      text: cleanText,
    );

    updateState(current.copyWith(
      chatMessages: [...current.chatMessages, message],
    ));

    // Resposta tática simulada de bots para manter o dinamismo da arena
    _simulateBotChatResponse(cleanText, targetChannel);
  }

  /// Dispara um anúncio automatizado de Sistema para todos os participantes (ex: Upgrades)
  void sendSystemMessage(String text) {
    final current = currentState;
    final message = ChatMessage.system(text: text);
    updateState(current.copyWith(
      chatMessages: [...current.chatMessages, message],
    ));
  }

  /// Simula respostas contextuais de aliados ou oponentes (Warcraft 3 / LoL bot interaction)
  void _simulateBotChatResponse(String playerText, ChatChannel channel) {
    if (_isDisposed) return;
    final lower = playerText.toLowerCase();

    Timer(const Duration(milliseconds: 900), () {
      if (_isDisposed) return;
      final current = currentState;

      if (channel == ChatChannel.team) {
        String botReply;
        TeamPlayerModel bot;
        if (lower.contains('mainframe') || lower.contains('defend') || lower.contains('proteger')) {
          bot = current.allyPlayers.length > 1 ? current.allyPlayers[1] : current.allyPlayers.first;
          botReply = 'Entendido! Concentrando defesas no perímetro do Mainframe.';
        } else if (lower.contains('bit') || lower.contains('ouro') || lower.contains('eco') || lower.contains('miner')) {
          bot = current.allyPlayers.length > 2 ? current.allyPlayers[2] : current.allyPlayers.first;
          botReply = 'Alocando novos mineradores para maximizar o rendimento.';
        } else if (lower.contains('atac') || lower.contains('wave') || lower.contains('mandar') || lower.contains('virus')) {
          bot = current.allyPlayers.length > 3 ? current.allyPlayers[3] : current.allyPlayers.first;
          botReply = 'Preparando malwares para sobrecarregar as rotas inimigas no próximo round.';
        } else {
          bot = current.allyPlayers.length > 1 ? current.allyPlayers[1] : current.allyPlayers.first;
          botReply = 'Copiado! Mantendo vigilância no setor.';
        }

        final botMsg = ChatMessage.player(
          senderId: bot.id,
          senderName: bot.name,
          senderColor: bot.color,
          channel: ChatChannel.team,
          text: botReply,
        );

        updateState(current.copyWith(
          chatMessages: [...current.chatMessages, botMsg],
        ));
      } else if (channel == ChatChannel.all) {
        final rival = current.opponentPlayers.isNotEmpty ? current.opponentPlayers.first : null;
        if (rival == null) return;

        String rivalReply = 'Nossos exploits vão encontrar qualquer brecha no seu firewall.';
        if (lower.contains('gg') || lower.contains('bom jogo') || lower.contains('gl') || lower.contains('hf')) {
          rivalReply = 'Boa partida! Que vença o melhor cluster.';
        }

        final rivalMsg = ChatMessage.player(
          senderId: rival.id,
          senderName: '${rival.name} (Adversário)',
          senderColor: rival.color,
          channel: ChatChannel.all,
          text: rivalReply,
        );

        updateState(current.copyWith(
          chatMessages: [...current.chatMessages, rivalMsg],
        ));
      }
    });
  }

  /// Reinicia a partida para o estado inicial
  void resetMatch() {
    executor.clearHistory();
    _pendingState = null;
    state.value = MatchState.initial();
    _initializeInitialDeckAndHand();
    notifyListeners();
    debugPrint('[BattleVM] Partida reiniciada.');
  }

  void _initializeInitialDeckAndHand() {
    final pool = [
      const GameCard(
        id: 'syn_flood',
        name: 'SYN Flooder',
        description: 'Envia enxame de pacotes leves para sobrecarregar buffers.',
        bandwidthCost: 3,
        rarity: CardRarity.common,
        type: CardType.exploit,
        icon: Icons.waves_rounded,
        basePower: 80,
      ),
      const GameCard(
        id: 'nmap_scan',
        name: 'Port Recon',
        description: 'Varre portas abertas e revela vulnerabilidades nos bastiões.',
        bandwidthCost: 2,
        rarity: CardRarity.common,
        type: CardType.exploit,
        icon: Icons.radar_rounded,
        basePower: 40,
      ),
      const GameCard(
        id: 'emergency_patch',
        name: 'Hot-Patch',
        description: 'Injeta regra emergencial restaurando 200 de integridade a um bastião.',
        bandwidthCost: 4,
        rarity: CardRarity.rare,
        type: CardType.patch,
        icon: Icons.build_circle_rounded,
        basePower: 200,
      ),
      const GameCard(
        id: 'jailbreak_payload',
        name: 'Jailbreak DAN',
        description: 'Payload avançado focado em atingir o Mainframe do adversário.',
        bandwidthCost: 6,
        rarity: CardRarity.legendary,
        type: CardType.payload,
        icon: Icons.terminal_rounded,
        basePower: 350,
      ),
      const GameCard(
        id: 'vpn_sentinel',
        name: 'Túnel WireGuard',
        description: 'Encapsula pacotes em canal seguro com imunidade a interceptação.',
        bandwidthCost: 5,
        rarity: CardRarity.epic,
        type: CardType.sentinel,
        icon: Icons.lock_outline_rounded,
        basePower: 250,
      ),
    ];

    updateState(currentState.copyWith(
      hand: pool.take(4).toList(),
      deck: pool.skip(4).toList(),
    ));
  }

  void _startTimers() {
    // Regeneração de Banda de Rede contínua
    _bandwidthTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      final current = currentState;
      // Geração de Bits contínua pelos processos mineradores
      final updatedEconomy = current.economy.updateBitGeneration(0.5);

      if (current.phase == MatchPhase.battle && current.bandwidth < current.maxBandwidth) {
        final newBandwidth = (current.bandwidth + current.bandwidthRegenRate).clamp(0.0, current.maxBandwidth);
        updateState(current.copyWith(bandwidth: newBandwidth, economy: updatedEconomy));
      } else {
        updateState(current.copyWith(economy: updatedEconomy));
      }
    });

    // Cronômetro da partida e telemetria de duração
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = currentState;
      if (current.phase == MatchPhase.battle) {
        updateState(current.copyWith(
          statsDurationSeconds: current.statsDurationSeconds + 1,
        ));
      } else if (current.phase == MatchPhase.preparation && current.remainingSeconds > 0) {
        final nextSec = current.remainingSeconds - 1;
        if (nextSec <= 0) {
          startBattlePhase();
        } else {
          updateState(current.copyWith(remainingSeconds: nextSec));
        }
      }
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bandwidthTimer?.cancel();
    _countdownTimer?.cancel();
    _flameDispatches.close();
    state.dispose();
    super.dispose();
  }
}
