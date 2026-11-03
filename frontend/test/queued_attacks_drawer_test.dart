import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_theme.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/tactical_virus_model.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/queued_attacks_drawer.dart';

void main() {
  testWidgets('QueuedAttacksDrawer displays empty state when queue is empty', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: const Scaffold(
          body: QueuedAttacksDrawer(
            queuedAttacks: [],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('FILA OFENSIVA (PRÓXIMO ROUND)'), findsOneWidget);
    expect(find.text('Nenhum malware na fila de despacho.'), findsOneWidget);
    expect(find.text('+0 Tokens / round'), findsOneWidget);
  });

  testWidgets('QueuedAttacksDrawer displays virus list and handles close action', (tester) async {
    bool closed = false;

    const testViruses = [
      TacticalVirusModel(
        id: 'worm_1',
        name: 'Worm Propagator',
        description: 'Multiplica-se rapidamente',
        bitCost: 35,
        incomeBonusTokens: 8,
        attackDamageBits: 45,
        packetHp: 50.0,
        packetSpeed: 70.0,
        icon: Icons.bug_report_rounded,
        color: Color(0xFFFF5500),
      ),
      TacticalVirusModel(
        id: 'rootkit_1',
        name: 'Rootkit Stealth',
        description: 'Ataque profundo',
        bitCost: 60,
        incomeBonusTokens: 15,
        attackDamageBits: 90,
        packetHp: 80.0,
        packetSpeed: 50.0,
        icon: Icons.security_rounded,
        color: Color(0xFF00D4FF),
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.darkTheme,
        home: Scaffold(
          body: QueuedAttacksDrawer(
            queuedAttacks: testViruses,
            onClose: () => closed = true,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Título e total de renda (+8 + 15 = +23)
    expect(find.text('FILA OFENSIVA (PRÓXIMO ROUND)'), findsOneWidget);
    expect(find.text('+23 Tokens / round'), findsOneWidget);

    // 2. Itens renderizados
    expect(find.text('#1 Worm Propagator'), findsOneWidget);
    expect(find.text('#2 Rootkit Stealth'), findsOneWidget);
    expect(find.text('+8T'), findsOneWidget);
    expect(find.text('+15T'), findsOneWidget);

    // 3. Botão Fechar
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });
}
