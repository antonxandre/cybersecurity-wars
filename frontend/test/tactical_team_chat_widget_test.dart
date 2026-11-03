import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_colors.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/chat_message.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/tactical_team_chat_widget.dart';

void main() {
  group('TacticalTeamChatWidget Component Tests', () {
    testWidgets('renders in passive HUD stream mode with recent messages', (tester) async {
      final messages = [
        ChatMessage.system(text: 'Cluster operacional.'),
        ChatMessage.player(
          senderId: 'player_blue_1',
          senderName: 'Jogador 1 (Você)',
          senderColor: AppColors.blueTeam,
          channel: ChatChannel.team,
          text: 'Foco no Mainframe!',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: messages,
              onSendMessage: (text, channel) {},
            ),
          ),
        ),
      );

      expect(find.text('CHAT [Enter]'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Foco no Mainframe!'),
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('Cluster operacional.'),
        ),
        findsOneWidget,
      );
      expect(find.text('[EQUIPE]'), findsOneWidget);
      expect(find.text('[SISTEMA]'), findsOneWidget);
    });

    testWidgets('expands when clicking CHAT bar and displays input and macros', (tester) async {
      final messages = [
        ChatMessage.system(text: 'Cluster operacional.'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: messages,
              onSendMessage: (text, channel) {},
            ),
          ),
        ),
      );

      // Clica na barra de acionamento do chat
      await tester.tap(find.text('CHAT [Enter]'));
      await tester.pumpAndSettle();

      // Confirma que o terminal expandido abriu
      expect(find.text('CHAT TÁTICO'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('🛡️ Defender o Mainframe!'), findsOneWidget);
      expect(find.text('⚡ Economizem Bits para combo!'), findsOneWidget);
    });

    testWidgets('toggles channel between [EQUIPE] and [TODOS] when clicking channel badge', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {},
            ),
          ),
        ),
      );

      // Inicialmente está no canal de equipe
      expect(find.text('Mensagem para a Equipe... (/all para todos)'), findsOneWidget);

      // Alterna canal clicando no seletor
      await tester.tap(find.byIcon(Icons.swap_horiz_rounded));
      await tester.pumpAndSettle();

      // Agora deve estar no canal global
      expect(find.text('Mensagem para Todos (Global)...'), findsOneWidget);
    });

    testWidgets('sends message via text field input and triggers onSendMessage callback', (tester) async {
      String? sentText;
      ChatChannel? sentChannel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {
                sentText = text;
                sentChannel = channel;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Ataquem juntos no próximo ciclo!');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(sentText, 'Ataquem juntos no próximo ciclo!');
      expect(sentChannel, ChatChannel.team);
    });

    testWidgets('sends message when clicking quick chat macro chip', (tester) async {
      String? sentText;
      ChatChannel? sentChannel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {
                sentText = text;
                sentChannel = channel;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('🛡️ Defender o Mainframe!'));
      await tester.pumpAndSettle();

      expect(sentText, '🛡️ Defender o Mainframe!');
      expect(sentChannel, ChatChannel.team);
    });

    testWidgets('sends message and closes chat when pressing Enter on keyboard', (tester) async {
      String? sentText;
      ChatChannel? sentChannel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {
                sentText = text;
                sentChannel = channel;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Rush no setor alfa!');
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(sentText, 'Rush no setor alfa!');
      expect(sentChannel, ChatChannel.team);
      // Confirma que fechou o terminal e voltou ao stream passivo
      expect(find.text('CHAT [Enter]'), findsOneWidget);
    });

    testWidgets('closes chat when pressing Enter with empty message', (tester) async {
      String? sentText;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {
                sentText = text;
              },
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();

      expect(sentText, isNull);
      expect(find.text('CHAT [Enter]'), findsOneWidget);
    });

    testWidgets('sends message and closes chat when clicking Send button', (tester) async {
      String? sentText;
      ChatChannel? sentChannel;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {
                sentText = text;
                sentChannel = channel;
              },
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Mensagem via botão');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(sentText, 'Mensagem via botão');
      expect(sentChannel, ChatChannel.team);
      expect(find.text('CHAT [Enter]'), findsOneWidget);
    });

    testWidgets('closes chat when pressing Escape key', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TacticalTeamChatWidget(
              messages: const [],
              initialExpanded: true,
              onSendMessage: (text, channel) {},
            ),
          ),
        ),
      );

      expect(find.text('CHAT TÁTICO'), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('CHAT [Enter]'), findsOneWidget);
    });
  });
}
