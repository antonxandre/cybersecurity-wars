import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/core/theme/app_colors.dart';
import 'package:promptsec_arena_front/features/battle/presentation/widgets/cyber_miner_icon.dart';

void main() {
  testWidgets('CyberMinerIcon renders with default properties', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CyberMinerIcon(),
        ),
      ),
    );

    expect(find.byType(CyberMinerIcon), findsOneWidget);
    expect(find.byType(CustomPaint), findsOneWidget);

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(of: find.byType(CyberMinerIcon), matching: find.byType(SizedBox)),
    );
    expect(sizedBox.width, 20.0);
    expect(sizedBox.height, 20.0);
  });

  testWidgets('CyberMinerIcon respects custom size and color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CyberMinerIcon(
            size: 32.0,
            color: AppColors.cpuClock,
            glowColor: Colors.amber,
          ),
        ),
      ),
    );

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(of: find.byType(CyberMinerIcon), matching: find.byType(SizedBox)),
    );
    expect(sizedBox.width, 32.0);
    expect(sizedBox.height, 32.0);
  });
}
