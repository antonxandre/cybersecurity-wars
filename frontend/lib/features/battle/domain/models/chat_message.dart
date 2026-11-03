import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Canal de destino da mensagem no chat da partida.
enum ChatChannel {
  /// Canal da Equipe Aliada (Warcraft 3 Allies / LoL Team Chat)
  team,

  /// Canal Global para Todos os Jogadores (Warcraft 3 All / LoL All Chat)
  all,

  /// Canal do Sistema para Anúncios Críticos de Infraestrutura / Mainframe
  system,
}

extension ChatChannelExtension on ChatChannel {
  String get tag {
    switch (this) {
      case ChatChannel.team:
        return '[EQUIPE]';
      case ChatChannel.all:
        return '[TODOS]';
      case ChatChannel.system:
        return '[SISTEMA]';
    }
  }

  String get label {
    switch (this) {
      case ChatChannel.team:
        return 'Equipe Aliada';
      case ChatChannel.all:
        return 'Todos (Global)';
      case ChatChannel.system:
        return 'Sistema Central';
    }
  }

  Color get tagColor {
    switch (this) {
      case ChatChannel.team:
        return AppColors.blueTeam; // Ciano Neon
      case ChatChannel.all:
        return const Color(0xFFFF9900); // Laranja / Âmbar Neon
      case ChatChannel.system:
        return AppColors.cpuClock; // Ouro / Amarelo Alerta
    }
  }
}

/// Mensagem individual trafegada no chat tático da partida.
class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final Color senderColor;
  final ChatChannel channel;
  final String text;
  final DateTime timestamp;
  final bool isSystem;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderColor,
    required this.channel,
    required this.text,
    required this.timestamp,
    this.isSystem = false,
  });

  /// Fábrica para mensagens automatizadas do Sistema (ex: Upgrades de Mainframe)
  factory ChatMessage.system({
    required String text,
    String? id,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    return ChatMessage(
      id: id ?? 'sys_${now.microsecondsSinceEpoch}',
      senderId: 'system_core',
      senderName: 'SISTEMA',
      senderColor: AppColors.cpuClock,
      channel: ChatChannel.system,
      text: text,
      timestamp: now,
      isSystem: true,
    );
  }

  /// Fábrica para mensagens enviadas por jogadores humanos ou bots
  factory ChatMessage.player({
    required String senderId,
    required String senderName,
    required Color senderColor,
    required ChatChannel channel,
    required String text,
    String? id,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();
    return ChatMessage(
      id: id ?? 'msg_${now.microsecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      senderColor: senderColor,
      channel: channel,
      text: text,
      timestamp: now,
      isSystem: false,
    );
  }

  String get formattedTime {
    final h = timestamp.hour.toString().padLeft(2, '0');
    final m = timestamp.minute.toString().padLeft(2, '0');
    final s = timestamp.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    Color? senderColor,
    ChatChannel? channel,
    String? text,
    DateTime? timestamp,
    bool? isSystem,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderColor: senderColor ?? this.senderColor,
      channel: channel ?? this.channel,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isSystem: isSystem ?? this.isSystem,
    );
  }
}
