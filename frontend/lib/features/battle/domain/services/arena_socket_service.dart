import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../core/network/socket_service.dart';
import '../models/chat_message.dart';
import '../models/tactical_virus_model.dart';

/// Serviço de integração em tempo real via Socket.IO para a Arena tática.
class ArenaSocketService {
  final SocketService socketService;

  final StreamController<TacticalVirusModel> _virusController =
      StreamController<TacticalVirusModel>.broadcast();
  final StreamController<ChatMessage> _chatController =
      StreamController<ChatMessage>.broadcast();
  final StreamController<Map<String, dynamic>> _stateController =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _tacticalActionController =
      StreamController<Map<String, dynamic>>.broadcast();

  String? _currentMatchId;

  ArenaSocketService({SocketService? socket})
      : socketService = socket ?? SocketService(namespace: '/arena') {
    _setupListeners();
  }

  String? get currentMatchId => _currentMatchId;
  Stream<SocketConnectionStatus> get statusStream => socketService.statusStream;
  bool get isConnected => socketService.isConnected;

  Stream<TacticalVirusModel> get onOpponentVirusReceived => _virusController.stream;
  Stream<ChatMessage> get onChatMessageReceived => _chatController.stream;
  Stream<Map<String, dynamic>> get onMatchStateChanged => _stateController.stream;
  Stream<Map<String, dynamic>> get onTacticalActionReceived =>
      _tacticalActionController.stream;

  void _setupListeners() {
    socketService.on('opponent:viruses_queued', (data) {
      if (data is List && data.isNotEmpty) {
        for (final item in data) {
          if (item is Map) {
            try {
              final id = item['id'] as String? ?? 'virus_remote';
              final virus = TacticalVirusModel.catalog.firstWhere(
                (v) => v.id == id,
                orElse: () => TacticalVirusModel(
                  id: id,
                  name: item['name'] as String? ?? 'Pacote Malicioso',
                  description: item['description'] as String? ?? 'Ataque remoto',
                  bitCost: (item['bitCost'] as num?)?.toInt() ?? 20,
                  incomeBonusTokens: (item['incomeBonusTokens'] as num?)?.toInt() ?? 5,
                  attackDamageBits: (item['attackDamageBits'] as num?)?.toDouble() ?? 25.0,
                  packetHp: (item['packetHp'] as num?)?.toDouble() ?? 50.0,
                  packetSpeed: (item['packetSpeed'] as num?)?.toDouble() ?? 60.0,
                  icon: Icons.bug_report_rounded,
                  color: const Color(0xFFFF4444),
                ),
              );
              _virusController.add(virus);
            } catch (e) {
              debugPrint('[ArenaSocket] Erro ao decodificar vírus remoto: $e');
            }
          }
        }
      }
    });

    socketService.on('chat:message', (data) {
      if (data is Map) {
        try {
          final channelStr = data['channel'] as String? ?? 'team';
          final channel = channelStr == 'all' ? ChatChannel.all : ChatChannel.team;
          final senderName = data['senderName'] as String? ?? 'Operador';
          final senderTeam = data['senderTeam'] as String? ?? 'blue';
          final text = data['text'] as String? ?? '';

          final msg = ChatMessage.player(
            senderId: data['id'] as String? ?? 'remote',
            senderName: senderName,
            senderColor: senderTeam == 'blue'
                ? const Color(0xFF00E5FF)
                : const Color(0xFFFF0055),
            channel: channel,
            text: text,
          );
          _chatController.add(msg);
        } catch (e) {
          debugPrint('[ArenaSocket] Erro ao decodificar mensagem de chat: $e');
        }
      }
    });

    socketService.on('match:state_changed', (data) {
      if (data is Map) {
        _stateController.add(Map<String, dynamic>.from(data));
      }
    });

    socketService.on('tactical:action_applied', (data) {
      if (data is Map) {
        _tacticalActionController.add(Map<String, dynamic>.from(data));
      }
    });
  }

  /// Conecta e junta-se à sala da partida.
  void joinMatch(String matchId, {String? team}) {
    _currentMatchId = matchId;
    socketService.connect();
    socketService.emit('join_match', {
      'matchId': matchId,
      if (team != null) 'team': team,
    });
  }

  /// Envia um vírus tático contra o oponente na partida remota.
  void sendVirus(String matchId, TacticalVirusModel virus) {
    socketService.emit('virus:send', {
      'matchId': matchId,
      'virus': {
        'id': virus.id,
        'name': virus.name,
        'bitCost': virus.bitCost,
        'incomeBonusTokens': virus.incomeBonusTokens,
        'attackDamageBits': virus.attackDamageBits,
        'packetHp': virus.packetHp,
        'packetSpeed': virus.packetSpeed,
      },
    });
  }

  /// Transmite uma mensagem de chat para os membros da partida.
  void sendChatMessage({
    required String matchId,
    required String text,
    ChatChannel channel = ChatChannel.team,
    String? senderName,
    String? senderTeam,
  }) {
    socketService.emit('chat:send', {
      'matchId': matchId,
      'text': text,
      'channel': channel == ChatChannel.all ? 'all' : 'team',
      if (senderName != null) 'senderName': senderName,
      if (senderTeam != null) 'senderTeam': senderTeam,
    });
  }

  /// Notifica uma ação tática (construção, upgrade, recrutamento).
  void sendTacticalAction({
    required String matchId,
    required String type,
    required Map<String, dynamic> payload,
  }) {
    socketService.emit('tactical:action', {
      'matchId': matchId,
      'type': type,
      'payload': payload,
    });
  }

  /// Sai da sala da partida e desconecta.
  void leaveMatch() {
    if (_currentMatchId != null) {
      socketService.emit('match:leave', {'matchId': _currentMatchId});
      _currentMatchId = null;
    }
    socketService.disconnect();
  }

  void dispose() {
    leaveMatch();
    socketService.dispose();
    _virusController.close();
    _chatController.close();
    _stateController.close();
    _tacticalActionController.close();
  }
}
