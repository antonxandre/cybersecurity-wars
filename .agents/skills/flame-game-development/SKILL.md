---
name: flame-game-development
description: Best practices for mobile and web 2D game development using Flutter and Flame Engine (flame-engine.org), featuring layered MVVM architecture with reusable Commands, component-driven design systems, and hybrid mechanics (Card Battler, Tower Defense, and Roguelite).
metadata:
  model: models/gemini-3.8-flash
  last_modified: Sat, 24 Oct 2026 13:36:00 GMT
---
# 🎮 Flame Game Development: Best Practices & Architecture Guide

Este guia estabelece as diretrizes de engenharia, arquitetura de software e padrões de design para o desenvolvimento de jogos 2D híbridos no **Flutter** utilizando o **Flame Engine** (`flame-engine.org`).

---

## 🏛️ 1. Arquitetura Híbrida: Flame Engine + Flutter UI

O segredo de jogos performáticos e escaláveis em Flutter é a **Separação Clara de Responsabilidades**:

```text
┌────────────────────────────────────────────────────────┐
│               FLUTTER PRESENTATION LAYER               │
│  • Overlays (HUD, Cards Dock, Menus, Modais de Perks)  │
│  • MVVM ViewModels (ChangeNotifier / ValueNotifier)    │
│  • Reusable Commands (DeployCardCommand, UpgradeNode)  │
│  • Design Tokens (AppColors, AppTypography, AppTheme)  │
└───────────────────────────┬────────────────────────────┘
                            │
               Reactivity & Events (Commands & Notifiers)
                            │
┌───────────────────────────▼────────────────────────────┐
│                  FLAME ENGINE CANVAS                   │
│  • FlameGame / World / CameraComponent                 │
│  • Render Loop & Physics (dt delta time)               │
│  • Entity-Component-System (PositionComponent, Shapes) │
│  • Particles, Shaders, Lasers & Sound FX               │
│  • Collision Detection (HasCollisionDetection)         │
└────────────────────────────────────────────────────────┘
```

### 1.1 Regra de Ouro das Camadas
1. **Flame Canvas (`FlameGame`)**: Cuida exclusivamente da simulação física, cálculo de movimento baseado em `dt` (delta time), posicionamento espacial de entidades, animação de pacotes/projéteis e partículas.
2. **Flutter Widgets (`Overlays`)**: Toda UI rica, botões, modais de upgrade/perks, cartas na mão, barras de status e textos descritivos devem ser **Flutter Widgets nativos**. Evite renderizar botões complexos e listas com scroll diretamente no canvas do Flame.
3. **Ponte de Comunicação**: O `FlameGame` recebe referências a `ValueNotifier` ou callbacks do ViewModel e despacha eventos limpos sem se acoplar à árvore de widgets.

---

## ⚡ 2. Arquitetura MVVM + Command Pattern para Jogos

Em jogos com múltiplas fases (preparação, combate em tempo real e seleção de perks), o **Command Pattern** desacopla a entrada do jogador da resolução da regra de negócio e permite:
* Validação de custo (`canExecute`)
* Desfazer ações na fase de preparação (`undo`)
* Replay determinístico e telemetria de ações
* Sincronização limpa com o backend via WebSockets

### 2.1 Interface Base de Command
```dart
abstract class GameCommand<TContext> {
  const GameCommand();

  /// Identificador para logs, métricas e eventos WebSocket
  String get commandType;

  /// Valida se o comando pode ser executado no estado atual
  bool canExecute(TContext context);

  /// Executa a ação sobre o contexto de jogo
  Future<void> execute(TContext context);

  /// Desfaz o comando (essencial para a fase de build/grid)
  Future<void> undo(TContext context) async {}

  /// Indica se o comando suporta rollback
  bool get canUndo => false;
}
```

### 2.2 Executor e Histórico de Comandos
```dart
class CommandExecutor<TContext> {
  final TContext context;
  final List<GameCommand<TContext>> _history = [];

  CommandExecutor(this.context);

  List<GameCommand<TContext>> get history => List.unmodifiable(_history);

  Future<bool> run(GameCommand<TContext> command) async {
    if (!command.canExecute(context)) {
      return false;
    }
    await command.execute(context);
    if (command.canUndo) {
      _history.add(command);
    }
    return true;
  }

  Future<bool> undoLast() async {
    if (_history.isEmpty) return false;
    final last = _history.removeLast();
    await last.undo(context);
    return true;
  }

  void clearHistory() => _history.clear();
}
```

---

## 🎨 3. Design System & Design Tokens Reutilizáveis

### 3.1 Paleta Cyberpunk Neon
Para jogos táticos com foco em cibersegurança:
* **Background Primário**: `#0A0E17` (Deep Obsidian / Terminal Dark)
* **Superfície / Cards**: `#121826` com bordas sutis neon `#1F293D`
* **Blue Team (Defesa)**: `#00F0FF` (Ciano Elétrico), `#0077FE` (Cobalto)
* **Red Team (Ataque)**: `#FF3366` (Carmesim Neon), `#FF5500` (Laranja Exploit)
* **Core / IA Sensível**: `#BD00FF` (Roxo Neon / Psíquico)
* **Recursos / Banda de Rede**: `#00FF66` (Verde Matrix)
* **Clock / CPU Cycles**: `#FFCC00` (Âmbar Ouro)

### 3.2 Componentes de UI Reutilizáveis
1. **`GameCardWidget`**: Exibe cartas no estilo Clash Royale (ícone, custo em banda/mana, raridade e indicador de cooldown).
2. **`ResourceBarWidget`**: Barra animada de recarga contínua (ex: 10 pontos de Banda de Rede).
3. **`PerkDraftDialog`**: Modal estilo Archero exibindo 3 cartas com borda brilhante e descrição de efeitos passivos.
4. **`CyberBadge`**: Chips com micro-animação para status de portas (`22/SSH`, `443/HTTPS`).

---

## 🧩 4. Padrões de Componentes no Flame Engine

### 4.1 Ciclo de Vida de um Componente Flame
* `onLoad()`: Carregamento assíncrono de assets, sprites, inicialização de hitboxes e filhos. **Sempre retorne `Future<void>`**.
* `update(double dt)`: Atualização de posição e estado multiplicando taxas por `dt`. **Nunca assuma framerate fixo de 60fps!**
* `render(Canvas canvas)`: Desenho manual com `Paint`, se não for um `SpriteComponent`.
* `onRemove()`: Descarte de timers, listeners e referências.

### 4.2 Exemplo de Entidade Reutilizável com Hitbox
```dart
class NetworkPacketComponent extends PositionComponent 
    with CollisionCallbacks, HasGameReference<CyberArenaGame> {
  final double speed;
  final Vector2 direction;
  final Color packetColor;

  NetworkPacketComponent({
    required Vector2 position,
    required this.direction,
    required this.speed,
    required this.packetColor,
  }) : super(position: position, size: Vector2(16, 16), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    // Hitbox circular para detecção rápida de colisão
    add(CircleHitbox());
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += direction * speed * dt;

    // Remove do mundo se sair dos limites da arena
    if (position.x > game.size.x || position.y > game.size.y) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = packetColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, paint);
  }
}
```

---

## 🕹️ 5. Mecânicas de Jogabilidade Híbridas

### 5.1 Fases do Jogo
1. **Fase de Preparação (Legion TD)**:
   * Grid de posições disponível para alocar nós defensivos (Firewall Bastion, Honeypot, WAF).
   * Sem consumo de vida/SLA.
   * Botão de "Desfazer Última Alocação" ativo via `undo()`.
   * Temporizador regressivo de Turno Zero (ex: 20 segundos) ou botão "Pronto".
2. **Fase de Combate em Tempo Real (Clash Royale)**:
   * Pacotes trafegam pelas rotas (lanes) conectando atacante e defensor.
   * Barra de energia (Banda de Rede) carrega de 0 a 10 continuamente.
   * Jogador arrasta/clica para disparar cartas (exploits rápidos, patches de emergência, escaneamento de portas).
3. **Fase de Perks Roguelite (Archero)**:
   * Ao atingir marcos de pontuação ou vencer uma onda, pausa breve na arena.
   * Exibição de 3 opções selecionadas aleatoriamente de um pool balanceado de modificadores (ex: `+25% Velocidade de Escaneamento`, `Criptografia Quântica Anti-Crack`, `Honeypot Refletivo`).

---

## 🚀 6. Otimizações Críticas para Flutter Web & Mobile

1. **Sprite Batching & Atlas**: Agrupe sprites em um único spritesheet com `Flame.images.load` para reduzir draw calls no WebGL / CanvasKit.
2. **Preloading de Assets**: Faça o preload de sons (`FlameAudio.audioCache.loadAll`) e imagens na tela de splash ou no `onLoad` do `FlameGame`.
3. **Uso do CanvasKit no Web**: No Flutter Web, configure o build para usar CanvasKit (`--web-renderer canvaskit`) para obter taxa de quadros estável a 60fps com shaders e blur effects.
4. **Isolamento de Repaints**: Use `RepaintBoundary` em torno de Overlays complexos de widgets para que animações do HUD não forcem o canvas do Flame a repintar e vice-versa.
