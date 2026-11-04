import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../../../core/network/socket_service.dart';
import '../../data/lobby_api_repository.dart';
import '../../data/lobby_mock_repository.dart';
import '../../domain/models/lobby_models.dart';

/// ViewModel reativo do Lobby de Jogo com suporte a matchmaking simulado,
/// gerenciamento de party e validação de segurança OWASP A03.
class LobbyViewModel extends ChangeNotifier {
  final LobbyRepository _repository;
  final SocketService _socketService;

  ValueChanged<String>? onMatchLaunchRequested;

  LobbyMode _currentMode = LobbyMode.createRoom;
  AiDifficulty _aiDifficulty = AiDifficulty.operador;
  bool _is2v2 = true;
  late String _generatedRoomCode;
  String _roomCodeInput = '';

  late PlayerProfile _profile;
  late List<LobbyFriend> _friends;
  late List<LobbyNewsItem> _news;
  late List<PublicRoom> _publicRooms;

  final List<String> _partyMembers = ['Você (Host)'];
  PublicRoom? _activeWaitingRoom;

  MatchmakingPhase _matchmakingPhase = MatchmakingPhase.idle;
  int _matchmakingElapsedSeconds = 0;
  int _countdownSeconds = 0;
  Timer? _matchmakingTicker;
  Timer? _matchmakingTransitionTimer;
  bool _isDisposed = false;

  LobbyViewModel({LobbyRepository? repository, SocketService? socketService})
      : _repository = repository ?? LobbyApiRepository(),
        _socketService = socketService ?? SocketService(namespace: '/arena') {
    _loadInitialData();
    _regenerateRoomCodeInternal();
    _setupSocketListeners();
    _socketService.connect();
  }

  // Getters de Estado
  LobbyMode get currentMode => _currentMode;
  AiDifficulty get aiDifficulty => _aiDifficulty;
  bool get is2v2 => _is2v2;
  String get generatedRoomCode => _generatedRoomCode;
  String get roomCodeInput => _roomCodeInput;
  PlayerProfile get profile => _profile;
  List<LobbyFriend> get friends => List.unmodifiable(_friends);
  List<LobbyNewsItem> get news => List.unmodifiable(_news);
  List<PublicRoom> get publicRooms => List.unmodifiable(_publicRooms);
  List<String> get partyMembers => List.unmodifiable(_partyMembers);
  PublicRoom? get activeWaitingRoom => _activeWaitingRoom;
  bool get isInWaitingRoom => _activeWaitingRoom != null;
  MatchmakingPhase get matchmakingPhase => _matchmakingPhase;
  int get matchmakingElapsedSeconds => _matchmakingElapsedSeconds;
  int get countdownSeconds => _countdownSeconds;
  bool get isSearchingMatch => _matchmakingPhase.isActive;

  int get maxPartySlots => _is2v2 ? 4 : 2;

  void _loadInitialData() {
    _profile = _repository.getPlayerProfile();
    _friends = _repository.getFriends();
    _news = _repository.getNews();
    _publicRooms = List<PublicRoom>.from(_repository.getPublicRooms());

    final repo = _repository;
    if (repo is LobbyApiRepository) {
      repo.fetchProfile().then((p) {
        if (_isDisposed) return;
        _profile = p;
        notifyListeners();
      });
      repo.fetchNews().then((n) {
        if (_isDisposed) return;
        _news = n;
        notifyListeners();
      });
      repo.fetchPublicRooms().then((r) {
        if (_isDisposed) return;
        _publicRooms = List<PublicRoom>.from(r);
        notifyListeners();
      });
    }
  }

  void setMode(LobbyMode mode) {
    if (_currentMode == mode) return;
    _currentMode = mode;
    notifyListeners();
  }

  void setAiDifficulty(AiDifficulty difficulty) {
    if (_aiDifficulty == difficulty) return;
    _aiDifficulty = difficulty;
    notifyListeners();
  }

  void setIs2v2(bool value) {
    if (_is2v2 == value) return;
    _is2v2 = value;
    // Se mudou para 1v1 e a party excede o limite, ajusta slots
    if (!_is2v2 && _partyMembers.length > 2) {
      _partyMembers.removeRange(2, _partyMembers.length);
    }
    notifyListeners();
  }

  void setRoomCodeInput(String value) {
    _roomCodeInput = value.toUpperCase().trim();
    notifyListeners();
  }

  void regenerateRoomCode() {
    _regenerateRoomCodeInternal();
    notifyListeners();
  }

  void _regenerateRoomCodeInternal() {
    final rand = Random();
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final part1 = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    final part2 = List.generate(3, (_) => chars[rand.nextInt(chars.length)]).join();
    _generatedRoomCode = '$part1-$part2';
  }

  /// Validação e sanitização estrita de código de sala (OWASP A03: Injection mitigation).
  /// Permite apenas letras maiúsculas e números no formato AAA-999.
  static String? sanitizeAndValidateRoomCode(String input) {
    final clean = input.trim().toUpperCase();
    final regex = RegExp(r'^[A-Z0-9]{3}-[A-Z0-9]{3}$');
    if (!regex.hasMatch(clean)) {
      return null;
    }
    return clean;
  }

  /// Define o nome de usuário do anfitrião da sala (evitando hardcoded 'Você (Host)').
  void setHostUsername(String name) {
    final hostLabel = name.trim().isNotEmpty ? '$name (Host)' : 'Você (Host)';
    if (_partyMembers.isEmpty) {
      _partyMembers.add(hostLabel);
    } else {
      _partyMembers[0] = hostLabel;
    }
    notifyListeners();
  }

  /// Adiciona dinamicamente um novo amigo à lista.
  void addFriend(String name) {
    final cleanName = name.trim();
    if (cleanName.isEmpty) return;
    if (_friends.any((f) => f.name.toLowerCase() == cleanName.toLowerCase())) return;

    final newFriend = LobbyFriend(
      id: 'fr_${DateTime.now().millisecondsSinceEpoch}',
      name: cleanName,
      status: FriendStatus.online,
      level: 1,
      activity: 'Disponível no Lobby',
    );
    _friends.add(newFriend);
    notifyListeners();
  }

  /// Remove amigo da lista.
  void removeFriend(String id) {
    _friends.removeWhere((f) => f.id == id);
    notifyListeners();
  }

  /// Convidar amigo para a party da sala.
  bool inviteFriend(LobbyFriend friend) {
    if (!friend.canInvite) return false;
    if (_partyMembers.contains(friend.name)) return false;
    if (_partyMembers.length >= maxPartySlots) return false;

    _partyMembers.add(friend.name);
    notifyListeners();
    return true;
  }

  /// Remover membro convidado da party.
  void removePartyMember(int index) {
    if (index <= 0 || index >= _partyMembers.length) return; // Não remove o host
    _partyMembers.removeAt(index);
    notifyListeners();
  }

  /// Inicia a simulação de Matchmaking cinematográfico.
  void startMatchmaking({required VoidCallback onReadyToLaunch}) {
    if (_matchmakingPhase != MatchmakingPhase.idle) return;

    _cancelTimers();
    _matchmakingPhase = MatchmakingPhase.searching;
    _matchmakingElapsedSeconds = 0;
    notifyListeners();

    // Contador de segundos
    _matchmakingTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _matchmakingElapsedSeconds++;
      notifyListeners();
    });

    // Simulação determinística de tempo de fila (entre 2 e 3 segundos para fluidez)
    _matchmakingTransitionTimer = Timer(const Duration(milliseconds: 2400), () {
      _matchmakingPhase = MatchmakingPhase.found;
      notifyListeners();

      _matchmakingTransitionTimer = Timer(const Duration(milliseconds: 1000), () {
        _matchmakingPhase = MatchmakingPhase.launching;
        notifyListeners();

        _matchmakingTransitionTimer = Timer(const Duration(milliseconds: 800), () {
          _cancelTimers();
          _matchmakingPhase = MatchmakingPhase.idle;
          notifyListeners();
          onReadyToLaunch();
        });
      });
    });
  }

  /// Inicia contagem regressiva 3... 2... 1... sincronizada entre todos os operadores.
  void startCountdownLaunch({required String code, required VoidCallback onComplete}) {
    if (_countdownSeconds > 0) return;
    _cancelTimers();
    _countdownSeconds = 3;
    _matchmakingPhase = MatchmakingPhase.launching;
    notifyListeners();

    _matchmakingTicker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed) {
        timer.cancel();
        return;
      }
      _countdownSeconds--;
      if (_countdownSeconds <= 0) {
        timer.cancel();
        _cancelTimers();
        _matchmakingPhase = MatchmakingPhase.idle;
        notifyListeners();
        onComplete();
      } else {
        notifyListeners();
      }
    });
  }

  /// Cancelamento de busca de partida pelo usuário.
  void cancelMatchmaking() {
    if (_matchmakingPhase == MatchmakingPhase.idle) return;
    _cancelTimers();
    _matchmakingPhase = MatchmakingPhase.idle;
    _matchmakingElapsedSeconds = 0;
    _countdownSeconds = 0;
    notifyListeners();
  }

  void _setupSocketListeners() {
    _socketService.on('lobby:room_created', (data) {
      if (_isDisposed || data is! Map) return;
      try {
        final newRoom = PublicRoom.fromJson(Map<String, dynamic>.from(data));
        final idx = _publicRooms.indexWhere((r) => r.code.toUpperCase() == newRoom.code.toUpperCase());
        if (idx != -1) {
          _publicRooms[idx] = newRoom;
        } else {
          _publicRooms.insert(0, newRoom);
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[LobbyViewModel] Erro em lobby:room_created: $e');
      }
    });

    void handleRoomUpdate(dynamic data) {
      if (_isDisposed || data is! Map) return;
      try {
        final updatedRoom = PublicRoom.fromJson(Map<String, dynamic>.from(data));
        final idx = _publicRooms.indexWhere((r) => r.code.toUpperCase() == updatedRoom.code.toUpperCase());
        if (idx != -1) {
          _publicRooms[idx] = updatedRoom;
        } else {
          _publicRooms.insert(0, updatedRoom);
        }

        if (_activeWaitingRoom != null &&
            (_activeWaitingRoom!.code.toUpperCase() == updatedRoom.code.toUpperCase() ||
                _activeWaitingRoom!.code == data['id'])) {
          _activeWaitingRoom = updatedRoom;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[LobbyViewModel] Erro ao processar atualização de sala: $e');
      }
    }

    _socketService.on('lobby:room_updated', handleRoomUpdate);
    _socketService.on('match:room_updated', handleRoomUpdate);
    _socketService.on('match:state_changed', handleRoomUpdate);

    _socketService.on('match:started', (data) {
      if (_isDisposed || data is! Map) return;
      final matchId = data['matchId']?.toString() ??
          (data['match'] is Map ? data['match']['code']?.toString() : null) ??
          '';
      final currentCode = _activeWaitingRoom?.code;
      if (currentCode != null &&
          (currentCode.toUpperCase() == matchId.toUpperCase() ||
              matchId.isEmpty ||
              (data['match'] is Map && data['match']['id'] == currentCode))) {
        _activeWaitingRoom = _activeWaitingRoom?.copyWith(status: 'IN_PROGRESS');
        notifyListeners();
        startCountdownLaunch(
          code: currentCode,
          onComplete: () {
            onMatchLaunchRequested?.call(currentCode);
          },
        );
      }
    });

    _socketService.on('match:player_left', (data) {
      if (_isDisposed) return;
      refreshPublicRooms();
    });

    _socketService.on('lobby:room_deleted', (data) {
      if (_isDisposed || data is! Map) return;
      try {
        final id = data['id']?.toString() ?? '';
        final code = data['code']?.toString() ?? '';
        _publicRooms.removeWhere((r) =>
            (code.isNotEmpty && r.code.toUpperCase() == code.toUpperCase()) ||
            (id.isNotEmpty && (r.code.toUpperCase() == id.toUpperCase() || r.code == id)));

        if (_activeWaitingRoom != null &&
            ((code.isNotEmpty && _activeWaitingRoom!.code.toUpperCase() == code.toUpperCase()) ||
                (id.isNotEmpty && _activeWaitingRoom!.code == id))) {
          _activeWaitingRoom = null;
          _cancelTimers();
          _matchmakingPhase = MatchmakingPhase.idle;
          _matchmakingElapsedSeconds = 0;
        }
        notifyListeners();
      } catch (e) {
        debugPrint('[LobbyViewModel] Erro em lobby:room_deleted: $e');
      }
    });

    _socketService.on('match:expired', (data) {
      if (_isDisposed) return;
      final id = data is Map ? data['id']?.toString() ?? '' : '';
      final code = data is Map ? data['code']?.toString() ?? '' : '';
      if (_activeWaitingRoom != null &&
          ((code.isNotEmpty && _activeWaitingRoom!.code.toUpperCase() == code.toUpperCase()) ||
              (id.isNotEmpty && _activeWaitingRoom!.code == id))) {
        _activeWaitingRoom = null;
        _cancelTimers();
        _matchmakingPhase = MatchmakingPhase.idle;
        _matchmakingElapsedSeconds = 0;
        notifyListeners();
      }
    });
  }

  /// Inicia a partida a partir do Host e notifica todos os operadores na sala via WebSocket.
  void triggerStartMatch({required ValueChanged<String> onReadyToLaunch}) {
    onMatchLaunchRequested = onReadyToLaunch;
    final currentRoom = _activeWaitingRoom;
    if (currentRoom != null) {
      _socketService.connect();
      _socketService.emit('start_match', {'matchId': currentRoom.code});
      if (!_socketService.isConnected) {
        _repository.startMatch(currentRoom.code);
        startCountdownLaunch(
          code: currentRoom.code,
          onComplete: () => onReadyToLaunch(currentRoom.code),
        );
      }
    }
  }

  /// Cria uma nova sala dedicada e ingressa o usuário imediatamente na Waiting Room como Host.
  /// Integra com o endpoint POST /api/matches via repositório.
  Future<PublicRoom> createRoom({bool? is2v2, String? customCode, String? scenarioId}) async {
    final use2v2 = is2v2 ?? _is2v2;
    final maxSlots = use2v2 ? 4 : 2;
    final code = customCode?.trim().isNotEmpty == true ? customCode!.trim() : _generatedRoomCode;
    final hostName = _partyMembers.isNotEmpty
        ? _partyMembers.first.replaceAll(' (Host)', '')
        : 'Você';

    PublicRoom? createdRoom;
    try {
      createdRoom = await _repository.createRoom(
        scenarioId: scenarioId ?? 'scenario-a',
        customCode: code,
        is2v2: use2v2,
        mode: use2v2 ? '2v2 Duplas' : '1v1 Duelo',
      );
    } catch (e) {
      debugPrint('[LobbyViewModel] Erro ao integrar criação de sala: $e');
    }

    final newRoom = createdRoom ??
        PublicRoom(
          code: code,
          host: hostName,
          mode: use2v2 ? '2v2 Duplas' : '1v1 Duelo',
          players: 1,
          maxPlayers: maxSlots,
          ping: 15,
          playerNames: [hostName],
        );

    // Adiciona ou substitui na lista de salas ativas
    final idx = _publicRooms.indexWhere((r) => r.code == newRoom.code);
    if (idx != -1) {
      _publicRooms[idx] = newRoom;
    } else {
      _publicRooms.insert(0, newRoom);
    }

    _activeWaitingRoom = newRoom;
    _regenerateRoomCodeInternal();

    // Registra conexão no socket da partida como Host (Blue Team)
    _socketService.connect();
    _socketService.emit('join_match', {
      'matchId': newRoom.code,
      'team': 'BLUE_TEAM',
    });

    notifyListeners();
    return newRoom;
  }

  /// Conecta o usuário a uma sala pública existente (se houver vagas disponíveis).
  /// Regra: Se a sala estiver cheia (players >= maxPlayers), recusa a conexão (retorna false).
  Future<bool> joinRoom(PublicRoom room) async {
    if (room.isFull) {
      return false;
    }

    final userName = _partyMembers.isNotEmpty
        ? _partyMembers.first.replaceAll(' (Host)', '')
        : 'Operador_Convidado';

    bool joinedViaApi = false;
    try {
      joinedViaApi = await _repository.joinRoom(room.code, team: 'RED_TEAM');
    } catch (e) {
      debugPrint('[LobbyViewModel] Erro ao sincronizar join com backend: $e');
    }

    if (!joinedViaApi && _repository is LobbyApiRepository) {
      debugPrint('[LobbyViewModel] Falha ao entrar na sala ${room.code} via API (sala cheia ou inexistente)');
      await refreshPublicRooms();
      return false;
    }

    // Registra conexão no socket da partida como Adversário (Red Team)
    _socketService.connect();
    _socketService.emit('join_match', {
      'matchId': room.code,
      'team': 'RED_TEAM',
    });

    final updatedPlayerNames = List<String>.from(room.playerNames);
    if (!updatedPlayerNames.contains(userName)) {
      updatedPlayerNames.add(userName);
    }

    final updatedRoom = room.copyWith(
      players: updatedPlayerNames.length,
      playerNames: updatedPlayerNames,
    );

    // Atualiza a lista de salas públicas
    final index = _publicRooms.indexWhere((r) => r.code == room.code);
    if (index != -1) {
      _publicRooms[index] = updatedRoom;
    }

    _activeWaitingRoom = updatedRoom;
    notifyListeners();
    return true;
  }

  /// Conecta a uma sala através de código alfanumérico digitado.
  Future<bool> joinRoomByCode(String code) async {
    final clean = sanitizeAndValidateRoomCode(code);
    if (clean == null) return false;

    final found = _publicRooms.where((r) => r.code.toUpperCase() == clean.toUpperCase()).firstOrNull;
    if (found != null) {
      return await joinRoom(found);
    }

    // Se o código não estiver em cache, atualiza da API para validar se existe
    await refreshPublicRooms();
    final foundAfterRefresh = _publicRooms.where((r) => r.code.toUpperCase() == clean.toUpperCase()).firstOrNull;
    if (foundAfterRefresh != null) {
      return await joinRoom(foundAfterRefresh);
    }

    // Sem criação de mock: rejeita caso a sala realmente não exista
    return false;
  }

  /// Sai da Waiting Room atual e retorna ao navegador de salas do Lobby.
  void leaveWaitingRoom() {
    if (_activeWaitingRoom != null) {
      _socketService.emit('match:leave', {'matchId': _activeWaitingRoom!.code});
      _activeWaitingRoom = null;
      notifyListeners();
    }
  }

  /// Simula a entrada de outro jogador na Waiting Room ativa (útil para testes de UI).
  bool simulateJoinSlot() {
    final current = _activeWaitingRoom;
    if (current == null || current.isFull) return false;

    final botNum = Random().nextInt(899) + 100;
    final newMember = 'CyberOperador_$botNum';
    final updatedList = List<String>.from(current.playerNames)..add(newMember);

    final updatedRoom = current.copyWith(
      players: updatedList.length,
      playerNames: updatedList,
    );

    final idx = _publicRooms.indexWhere((r) => r.code == current.code);
    if (idx != -1) {
      _publicRooms[idx] = updatedRoom;
    }

    _activeWaitingRoom = updatedRoom;
    notifyListeners();
    return true;
  }

  /// Atualiza a lista de salas consultando a API ou recalculando pings.
  Future<void> refreshPublicRooms() async {
    final repo = _repository;
    if (repo is LobbyApiRepository) {
      try {
        final rooms = await repo.fetchPublicRooms();
        if (_isDisposed) return;
        _publicRooms = List<PublicRoom>.from(rooms);
        notifyListeners();
      } catch (e) {
        debugPrint('[LobbyViewModel] Erro ao atualizar salas da API: $e');
      }
      return;
    }

    final rand = Random();
    _publicRooms = _publicRooms.map((r) {
      final variation = rand.nextInt(7) - 3;
      final newPing = (r.ping + variation).clamp(10, 180);
      return r.copyWith(ping: newPing);
    }).toList();
    notifyListeners();
  }

  void _cancelTimers() {
    _matchmakingTicker?.cancel();
    _matchmakingTicker = null;
    _matchmakingTransitionTimer?.cancel();
    _matchmakingTransitionTimer = null;
    _countdownSeconds = 0;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _cancelTimers();
    _socketService.off('lobby:room_created');
    _socketService.off('lobby:room_updated');
    _socketService.off('match:room_updated');
    _socketService.off('match:state_changed');
    _socketService.off('match:started');
    _socketService.off('match:player_left');
    _socketService.off('lobby:room_deleted');
    _socketService.off('match:expired');
    _socketService.dispose();
    super.dispose();
  }
}
