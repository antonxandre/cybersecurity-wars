import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/features/lobby/domain/models/lobby_models.dart';
import 'package:promptsec_arena_front/features/lobby/presentation/viewmodels/lobby_view_model.dart';

void main() {
  group('LobbyViewModel Tests', () {
    late LobbyViewModel viewModel;

    setUp(() {
      viewModel = LobbyViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('Initial state loads profile, news, empty friends, empty public rooms, and default mode', () {
      expect(viewModel.currentMode, LobbyMode.createRoom);
      expect(viewModel.aiDifficulty, AiDifficulty.operador);
      expect(viewModel.is2v2, true);
      expect(viewModel.maxPartySlots, 4);
      expect(viewModel.profile.level, 42);
      expect(viewModel.profile.wins, 128);
      expect(viewModel.profile.losses, 56);
      expect(viewModel.profile.winStreak, 5);
      expect(viewModel.profile.totalPurges, 412);
      expect(viewModel.friends.isEmpty, true); // Sem amigos fixos / hardcoded
      expect(viewModel.publicRooms.isEmpty, true); // Sem salas mockadas ativas fixas
      expect(viewModel.news.isNotEmpty, true);
      expect(viewModel.partyMembers, ['Você (Host)']);
      expect(viewModel.matchmakingPhase, MatchmakingPhase.idle);
      expect(viewModel.isSearchingMatch, false);
    });

    test('setHostUsername dynamically updates host member name', () {
      viewModel.setHostUsername('CyberKnight');
      expect(viewModel.partyMembers.first, 'CyberKnight (Host)');

      viewModel.setHostUsername('');
      expect(viewModel.partyMembers.first, 'Você (Host)');
    });

    test('addFriend and removeFriend manage friends list dynamically', () {
      expect(viewModel.friends.isEmpty, true);

      viewModel.addFriend('ZeroDay_Hunter');
      expect(viewModel.friends.length, 1);
      expect(viewModel.friends.first.name, 'ZeroDay_Hunter');
      expect(viewModel.friends.first.status, FriendStatus.online);

      // Não adiciona duplicata
      viewModel.addFriend('zeroday_hunter');
      expect(viewModel.friends.length, 1);

      final friendId = viewModel.friends.first.id;
      viewModel.removeFriend(friendId);
      expect(viewModel.friends.isEmpty, true);
    });

    test('Mode switching updates currentMode and notifies listeners', () {
      int notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setMode(LobbyMode.soloAi);
      expect(viewModel.currentMode, LobbyMode.soloAi);
      expect(notifications, 1);

      viewModel.setMode(LobbyMode.createRoom);
      expect(viewModel.currentMode, LobbyMode.createRoom);
      expect(notifications, 2);
    });

    test('AiDifficulty updates correctly', () {
      viewModel.setAiDifficulty(AiDifficulty.mestre);
      expect(viewModel.aiDifficulty, AiDifficulty.mestre);
    });

    test('1v1 vs 2v2 toggle adjusts maxPartySlots and trims extra members', () {
      // Adiciona dinamicamente amigos e os convida
      viewModel.addFriend('Friend1');
      viewModel.addFriend('Friend2');
      viewModel.addFriend('Friend3');

      for (final f in viewModel.friends) {
        viewModel.inviteFriend(f);
      }
      expect(viewModel.partyMembers.length, 4);

      // Alterna para 1v1: deve limitar a 2 membros
      viewModel.setIs2v2(false);
      expect(viewModel.is2v2, false);
      expect(viewModel.maxPartySlots, 2);
      expect(viewModel.partyMembers.length, 2);
    });

    test('OWASP A03: sanitizeAndValidateRoomCode accepts valid formats and rejects injection', () {
      // Válidos
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('CYB-709'), 'CYB-709');
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('cyb-709'), 'CYB-709');
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('  NET-404  '), 'NET-404');
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('AAA-111'), 'AAA-111');

      // Inválidos / Tentativas de injeção
      expect(LobbyViewModel.sanitizeAndValidateRoomCode(''), isNull);
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('CYB709'), isNull);
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('CYB-709; DROP TABLE rooms;--'), isNull);
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('<script>alert(1)</script>'), isNull);
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('CYB-7090'), isNull);
      expect(LobbyViewModel.sanitizeAndValidateRoomCode('CY-709'), isNull);
    });

    test('inviteFriend adds eligible friends and respects limits', () {
      viewModel.addFriend('OnlineFriend');
      final onlineFriend = viewModel.friends.first;

      // Amigo online é adicionado
      final invited = viewModel.inviteFriend(onlineFriend);
      expect(invited, true);
      expect(viewModel.partyMembers.contains(onlineFriend.name), true);

      // Não convida duas vezes
      expect(viewModel.inviteFriend(onlineFriend), false);

      // Amigo offline não é convidado
      const offlineFriend = LobbyFriend(
        id: 'fr_offline',
        name: 'OfflineFriend',
        status: FriendStatus.offline,
        level: 10,
      );
      expect(viewModel.inviteFriend(offlineFriend), false);
    });

    test('removePartyMember removes guests but preserves Host', () {
      viewModel.addFriend('OnlineFriend');
      final friend = viewModel.friends.first;
      viewModel.inviteFriend(friend);
      expect(viewModel.partyMembers.length, 2);

      // Tentar remover index 0 (Host) não deve alterar
      viewModel.removePartyMember(0);
      expect(viewModel.partyMembers.length, 2);

      // Remover index 1 (Convidado)
      viewModel.removePartyMember(1);
      expect(viewModel.partyMembers.length, 1);
      expect(viewModel.partyMembers.first, 'Você (Host)');
    });

    test('Matchmaking can be started and cancelled immediately', () {
      bool launched = false;
      viewModel.startMatchmaking(onReadyToLaunch: () => launched = true);

      expect(viewModel.matchmakingPhase, MatchmakingPhase.searching);
      expect(viewModel.isSearchingMatch, true);
      expect(launched, false);

      viewModel.cancelMatchmaking();
      expect(viewModel.matchmakingPhase, MatchmakingPhase.idle);
      expect(viewModel.isSearchingMatch, false);
      expect(launched, false);
    });

    test('createRoom enters Waiting Room as Host and prepends to publicRooms', () async {
      expect(viewModel.isInWaitingRoom, false);
      expect(viewModel.activeWaitingRoom, isNull);

      final initialCount = viewModel.publicRooms.length;
      final newRoom = await viewModel.createRoom(is2v2: true);

      expect(viewModel.isInWaitingRoom, true);
      expect(viewModel.activeWaitingRoom, isNotNull);
      expect(viewModel.activeWaitingRoom!.code, newRoom.code);
      expect(viewModel.activeWaitingRoom!.mode, '2v2 Duplas');
      expect(viewModel.activeWaitingRoom!.players, 1);
      expect(viewModel.activeWaitingRoom!.maxPlayers, 4);
      expect(viewModel.publicRooms.length, initialCount + 1);
      expect(viewModel.publicRooms.first.code, newRoom.code);
    });

    test('joinRoom respects full room rule: rejects full rooms and admits available rooms', () async {
      // Sala cheia (4/4)
      const fullRoom = PublicRoom(
        code: 'FUL-999',
        host: 'ProHost',
        mode: '2v2 Duplas',
        players: 4,
        maxPlayers: 4,
        ping: 20,
        playerNames: ['P1', 'P2', 'P3', 'P4'],
      );
      expect(fullRoom.isFull, true);
      expect(fullRoom.hasSlots, false);

      final joinFull = await viewModel.joinRoom(fullRoom);
      expect(joinFull, false);
      expect(viewModel.isInWaitingRoom, false);

      // Sala disponível (1/2)
      const availableRoom = PublicRoom(
        code: 'AVA-101',
        host: 'SoloHost',
        mode: '1v1 Duelo',
        players: 1,
        maxPlayers: 2,
        ping: 25,
        playerNames: ['SoloHost'],
      );
      expect(availableRoom.isFull, false);
      expect(availableRoom.hasSlots, true);

      final joinAvailable = await viewModel.joinRoom(availableRoom);
      expect(joinAvailable, true);
      expect(viewModel.isInWaitingRoom, true);
      expect(viewModel.activeWaitingRoom!.code, 'AVA-101');
      expect(viewModel.activeWaitingRoom!.players, 2);
    });

    test('joinRoomByCode rejects nonexistent code without generating fake mock rooms', () async {
      final success = await viewModel.joinRoomByCode('NON-999');
      expect(success, false);
      expect(viewModel.isInWaitingRoom, false);
    });

    test('leaveWaitingRoom clears active room and returns to idle lobby', () async {
      await viewModel.createRoom();
      expect(viewModel.isInWaitingRoom, true);

      viewModel.leaveWaitingRoom();
      expect(viewModel.isInWaitingRoom, false);
      expect(viewModel.activeWaitingRoom, isNull);
    });

    test('simulateJoinSlot fills open slots up to maxPlayers', () async {
      await viewModel.createRoom(is2v2: false); // 1v1 -> max 2 players
      expect(viewModel.activeWaitingRoom!.players, 1);

      final joined1 = viewModel.simulateJoinSlot();
      expect(joined1, true);
      expect(viewModel.activeWaitingRoom!.players, 2);
      expect(viewModel.activeWaitingRoom!.isFull, true);

      // Tentativa adicional quando cheia deve retornar false
      final joined2 = viewModel.simulateJoinSlot();
      expect(joined2, false);
      expect(viewModel.activeWaitingRoom!.players, 2);
    });
  });
}
