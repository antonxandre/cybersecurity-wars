import 'dart:async';
import 'package:flutter/foundation.dart';
import 'game_command.dart';

/// Executor de Comandos com pilha de histórico (Undo/Redo) e telemetria.
class CommandExecutor<TContext> {
  final TContext context;
  final List<GameCommand<TContext>> _history = [];
  final ValueNotifier<int> commandCount = ValueNotifier(0);

  CommandExecutor(this.context);

  List<GameCommand<TContext>> get history => List.unmodifiable(_history);

  /// Executa o comando se as pré-condições forem satisfeitas.
  Future<bool> run(GameCommand<TContext> command) async {
    if (!command.canExecute(context)) {
      debugPrint('[CommandExecutor] Falha ao executar: ${command.commandType} (canExecute == false)');
      return false;
    }

    try {
      await command.execute(context);
      if (command.canUndo) {
        _history.add(command);
      }
      commandCount.value++;
      debugPrint('[CommandExecutor] Sucesso: ${command.commandType}');
      return true;
    } catch (e, stack) {
      debugPrint('[CommandExecutor] Erro na execução de ${command.commandType}: $e\n$stack');
      return false;
    }
  }

  /// Desfaz o último comando que suporta rollback.
  Future<bool> undoLast() async {
    if (_history.isEmpty) return false;
    final lastCommand = _history.removeLast();
    try {
      await lastCommand.undo(context);
      commandCount.value++;
      debugPrint('[CommandExecutor] Undo executado para: ${lastCommand.commandType}');
      return true;
    } catch (e) {
      debugPrint('[CommandExecutor] Falha no undo de ${lastCommand.commandType}: $e');
      return false;
    }
  }

  /// Limpa o histórico de comandos (ex: na transição de fases do jogo).
  void clearHistory() {
    _history.clear();
  }
}
