import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_colors.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/chat_message.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_state.dart';
import 'package:promptsec_arena_front/features/battle/presentation/viewmodels/battle_view_model.dart';

void main() {
  group('ChatMessage & ChatChannel Domain Model Tests', () {
    test('ChatChannel tags, labels and colors are correct', () {
      expect(ChatChannel.team.tag, '[EQUIPE]');
      expect(ChatChannel.team.label, 'Equipe Aliada');
      expect(ChatChannel.team.tagColor, AppColors.blueTeam);

      expect(ChatChannel.all.tag, '[TODOS]');
      expect(ChatChannel.all.label, 'Todos (Global)');
      expect(ChatChannel.all.tagColor, const Color(0xFFFF9900));

      expect(ChatChannel.system.tag, '[SISTEMA]');
      expect(ChatChannel.system.label, 'Sistema Central');
      expect(ChatChannel.system.tagColor, AppColors.cpuClock);
    });

    test('ChatMessage.system factory creates valid system announcement', () {
      final msg = ChatMessage.system(
        text: '[MAINFRAME] Upgrade realizado: OVERCLOCK DE CPU (Lv. 2)',
      );

      expect(msg.isSystem, true);
      expect(msg.channel, ChatChannel.system);
      expect(msg.senderName, 'SISTEMA');
      expect(msg.senderColor, AppColors.cpuClock);
      expect(msg.text, '[MAINFRAME] Upgrade realizado: OVERCLOCK DE CPU (Lv. 2)');
      expect(msg.formattedTime.isNotEmpty, true);
    });

    test('ChatMessage.player factory creates valid player message', () {
      final msg = ChatMessage.player(
        senderId: 'player_blue_1',
        senderName: 'Jogador 1 (Você)',
        senderColor: AppColors.blueTeam,
        channel: ChatChannel.team,
        text: 'Defendam o Mainframe!',
      );

      expect(msg.isSystem, false);
      expect(msg.channel, ChatChannel.team);
      expect(msg.senderId, 'player_blue_1');
      expect(msg.senderName, 'Jogador 1 (Você)');
      expect(msg.text, 'Defendam o Mainframe!');
    });

    test('MatchState.initial includes welcoming system chat message', () {
      final state = MatchState.initial();
      expect(state.chatMessages.isNotEmpty, true);
      expect(state.chatMessages.first.isSystem, true);
      expect(state.chatMessages.first.text, contains('Conexão segura estabelecida'));
    });
  });

  group('BattleViewModel Chat Orchestration Tests', () {
    late BattleViewModel viewModel;

    setUp(() {
      viewModel = BattleViewModel();
    });

    tearDown(() {
      viewModel.dispose();
    });

    test('sendChatMessage sends message to team channel', () {
      viewModel.sendChatMessage(
        text: 'Vamos proteger o quadrante norte!',
        channel: ChatChannel.team,
      );

      final messages = viewModel.currentState.chatMessages;
      expect(messages.any((m) => m.text == 'Vamos proteger o quadrante norte!'), true);
      final lastMsg = messages.lastWhere((m) => m.text == 'Vamos proteger o quadrante norte!');
      expect(lastMsg.channel, ChatChannel.team);
      expect(lastMsg.senderName, contains('Jogador 1'));
    });

    test('sendChatMessage detects /all command and routes to all channel', () {
      viewModel.sendChatMessage(
        text: '/all Boa partida a todos!',
      );

      final messages = viewModel.currentState.chatMessages;
      final msg = messages.firstWhere((m) => m.text == 'Boa partida a todos!');
      expect(msg.channel, ChatChannel.all);
    });

    test('sendChatMessage detects /todos command and routes to all channel', () {
      viewModel.sendChatMessage(
        text: '/todos gg wp',
      );

      final messages = viewModel.currentState.chatMessages;
      final msg = messages.firstWhere((m) => m.text == 'gg wp');
      expect(msg.channel, ChatChannel.all);
    });

    test('sendChatMessage detects /team command and routes to team channel', () {
      viewModel.sendChatMessage(
        text: '/team Economizem Bits!',
        channel: ChatChannel.all, // should be overridden by /team prefix
      );

      final messages = viewModel.currentState.chatMessages;
      final msg = messages.firstWhere((m) => m.text == 'Economizem Bits!');
      expect(msg.channel, ChatChannel.team);
    });

    test('sendSystemMessage broadcasts system notification', () {
      viewModel.sendSystemMessage(
        '[MAINFRAME] Upgrade realizado: EXPANSÃO DE RAM (Lv. 2)',
      );

      final messages = viewModel.currentState.chatMessages;
      final last = messages.last;
      expect(last.isSystem, true);
      expect(last.channel, ChatChannel.system);
      expect(last.text, '[MAINFRAME] Upgrade realizado: EXPANSÃO DE RAM (Lv. 2)');
    });
  });
}
