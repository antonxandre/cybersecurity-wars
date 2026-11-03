import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/network/socket_service.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/chat_message.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/tactical_virus_model.dart';
import 'package:promptsec_arena_front/features/battle/domain/services/arena_socket_service.dart';

class MockSocketService extends SocketService {
  final Map<String, void Function(dynamic)> listeners = {};
  final List<Map<String, dynamic>> emittedEvents = [];
  bool connected = false;

  MockSocketService() : super(namespace: '/arena');

  @override
  bool get isConnected => connected;

  @override
  void connect() {
    connected = true;
  }

  @override
  void disconnect() {
    connected = false;
  }

  @override
  void on(String event, void Function(dynamic data) handler) {
    listeners[event] = handler;
  }

  @override
  void emit(String event, [dynamic data, Function? ack]) {
    emittedEvents.add({'event': event, 'data': data});
  }

  void triggerEvent(String event, dynamic data) {
    listeners[event]?.call(data);
  }
}

void main() {
  late MockSocketService mockSocket;
  late ArenaSocketService arenaSocket;

  setUp(() {
    mockSocket = MockSocketService();
    arenaSocket = ArenaSocketService(socket: mockSocket);
  });

  tearDown(() {
    arenaSocket.dispose();
  });

  test('joinMatch emits join_match event and connects', () {
    arenaSocket.joinMatch('match_123', team: 'BLUE_TEAM');

    expect(mockSocket.connected, isTrue);
    expect(arenaSocket.currentMatchId, 'match_123');
    expect(mockSocket.emittedEvents.any((e) =>
        e['event'] == 'join_match' &&
        (e['data'] as Map)['matchId'] == 'match_123' &&
        (e['data'] as Map)['team'] == 'BLUE_TEAM'), isTrue);
  });

  test('sendVirus emits virus:send event with virus properties', () {
    const virus = TacticalVirusModel(
      id: 'trojan_1',
      name: 'Trojan Banker',
      description: 'Desc',
      bitCost: 40,
      incomeBonusTokens: 10,
      attackDamageBits: 50.0,
      packetHp: 60.0,
      packetSpeed: 65.0,
      icon: Icons.bug_report_rounded,
    );

    arenaSocket.sendVirus('match_123', virus);

    expect(mockSocket.emittedEvents.any((e) =>
        e['event'] == 'virus:send' &&
        (e['data'] as Map)['matchId'] == 'match_123' &&
        ((e['data'] as Map)['virus'] as Map)['id'] == 'trojan_1'), isTrue);
  });

  test('sendChatMessage emits chat:send event', () {
    arenaSocket.sendChatMessage(
      matchId: 'match_123',
      text: 'Defender o Mainframe!',
      channel: ChatChannel.team,
      senderName: 'Operador Ghost',
    );

    expect(mockSocket.emittedEvents.any((e) =>
        e['event'] == 'chat:send' &&
        (e['data'] as Map)['matchId'] == 'match_123' &&
        (e['data'] as Map)['text'] == 'Defender o Mainframe!' &&
        (e['data'] as Map)['senderName'] == 'Operador Ghost'), isTrue);
  });

  test('receives opponent:viruses_queued event and pushes to stream', () async {
    final receivedViruses = <TacticalVirusModel>[];
    final sub = arenaSocket.onOpponentVirusReceived.listen(receivedViruses.add);

    mockSocket.triggerEvent('opponent:viruses_queued', [
      {
        'id': 'botnet_drone',
        'name': 'DDoS Drone',
        'bitCost': 20,
        'incomeBonusTokens': 5,
        'attackDamageBits': 20,
        'packetHp': 40.0,
        'packetSpeed': 80.0,
      }
    ]);

    await pumpEventQueue();
    expect(receivedViruses.length, 1);
    expect(receivedViruses.first.id, 'botnet_drone');

    await sub.cancel();
  });

  test('receives chat:message event and pushes ChatMessage to stream', () async {
    final receivedMessages = <ChatMessage>[];
    final sub = arenaSocket.onChatMessageReceived.listen(receivedMessages.add);

    mockSocket.triggerEvent('chat:message', {
      'id': 'msg_1',
      'channel': 'all',
      'senderName': 'RedOperador',
      'senderTeam': 'red',
      'text': 'Preparando invasão!',
    });

    await pumpEventQueue();
    expect(receivedMessages.length, 1);
    expect(receivedMessages.first.text, 'Preparando invasão!');
    expect(receivedMessages.first.channel, ChatChannel.all);
    expect(receivedMessages.first.senderName, 'RedOperador');

    await sub.cancel();
  });
}
