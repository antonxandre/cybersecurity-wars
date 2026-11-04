import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_state.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/arena_atmosphere_overlay.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/match_header_widget.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/tactical_notification_toast.dart';

void main() {
  testWidgets('MatchHeaderWidget renders MOBA scoreboard and mainframe bars',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    bool readyPressed = false;
    bool undoPressed = false;

    final state = MatchState.initial();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: MatchHeaderWidget(
            state: state,
            onUndoBuild: () => undoPressed = true,
            onReadyPressed: () => readyPressed = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Verifica presença do placar MOBA (Mainframes e timer)
    expect(find.text('MAINFRAME ALIADO'), findsOneWidget);
    expect(find.text('MAINFRAME RIVAL'), findsOneWidget);
    expect(find.text('Cyber Arena (4v4)'), findsOneWidget);
    expect(find.text('ONDA 1/10'), findsOneWidget);

    // 2. Verifica botões de ação da fase de preparação
    final readyBtn = find.text('PRONTO');
    expect(readyBtn, findsOneWidget);
    await tester.tap(readyBtn);
    expect(readyPressed, isTrue);

    final undoBtn = find.text('DESFAZER');
    expect(undoBtn, findsOneWidget);
    await tester.tap(undoBtn);
    expect(undoPressed, isTrue);
  });

  testWidgets('TacticalNotificationToast displays item and triggers dismiss',
      (tester) async {
    bool dismissed = false;
    final item = TacticalNotificationItem(
      id: 'test-1',
      title: 'MALWARE ENVIADO',
      message: 'Port Scanner adicionado à fila',
      icon: Icons.radar_rounded,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: TacticalNotificationToast(
            notification: item,
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('MALWARE ENVIADO'), findsOneWidget);
    expect(find.text('Port Scanner adicionado à fila'), findsOneWidget);

    final closeBtn = find.byIcon(Icons.close_rounded);
    expect(closeBtn, findsOneWidget);
    await tester.tap(closeBtn);
    expect(dismissed, isTrue);
  });

  testWidgets('ArenaAtmosphereOverlay renders without intercepting pointer',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ArenaAtmosphereOverlay(isCriticalAlert: true),
        ),
      ),
    );

    final overlayFinder = find.byType(ArenaAtmosphereOverlay);
    expect(overlayFinder, findsOneWidget);
    final ignorePointer = tester.widget<IgnorePointer>(
      find.descendant(of: overlayFinder, matching: find.byType(IgnorePointer)),
    );
    expect(ignorePointer.ignoring, isTrue);
  });
}
