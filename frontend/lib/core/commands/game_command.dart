import 'dart:async';

/// Interface base para o Command Pattern aplicado a mecânicas de jogo.
/// Desacopla a intenção de entrada (UI do jogador) da resolução de regras de negócio.
abstract class GameCommand<TContext> {
  const GameCommand();

  /// Identificador do tipo de comando (para logs, replay e eventos WebSocket).
  String get commandType;

  /// Valida se o comando possui recursos suficientes (banda, CPU, cooldown) para ser executado.
  bool canExecute(TContext context);

  /// Executa o comando sobre o contexto da partida.
  Future<void> execute(TContext context);

  /// Desfaz o comando. Crucial para o Turno Zero (Fase de Build/Grid estilo Legion TD).
  Future<void> undo(TContext context) async {}

  /// Indica se esta ação pode ser desfeita pelo jogador.
  bool get canUndo => false;

  /// Custo de recursos (ex: pontos de Banda de Rede) para execução.
  int get resourceCost => 0;
}
