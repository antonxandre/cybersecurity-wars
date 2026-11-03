import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/features/battle/domain/models/match_state.dart';
import 'package:promptsec_arena_front/features/battle/presentation/viewmodels/battle_view_model.dart';

void main() {
  group('BattleViewModel updateState during build phase tests', () {
    testWidgets('updateState called within LayoutBuilder does not throw markNeedsBuild during build', (tester) async {
      final vm = BattleViewModel();

      bool updateCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<MatchState>(
              valueListenable: vm.state,
              builder: (context, state, child) {
                return Column(
                  children: [
                    Text('Phase: ${state.phase.name}'),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        if (!updateCalled) {
                          updateCalled = true;
                          // Simula a chamada da engine Flame / WaveSpawner durante o layout do GameWidget
                          vm.onWaveVictory(1);
                        }
                        return const SizedBox(width: 100, height: 100);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      // Não deve lançar FlutterError de setState() called during build
      expect(tester.takeException(), isNull);
      expect(updateCalled, isTrue);

      // Avança o frame para processar o postFrameCallback
      await tester.pump();

      expect(vm.currentState.currentWave, equals(2));
      expect(find.text('Phase: preparation'), findsOneWidget);

      vm.dispose();
    });

    test('currentState provides pending state before frame flush', () {
      final vm = BattleViewModel();
      addTearDown(vm.dispose);

      final initialState = vm.currentState;
      expect(initialState.currentWave, equals(1));

      vm.updateState(initialState.copyWith(currentWave: 3));
      expect(vm.currentState.currentWave, equals(3));
    });
  });
}
