import 'fullscreen_helper_stub.dart'
    if (dart.library.html) 'fullscreen_helper_web.dart' as platform;

/// Utilitário multi-plataforma para alternância e padronização do modo Fullscreen (Web, Mobile, Desktop).
class FullscreenHelper {
  FullscreenHelper._();

  /// Inicializa o modo de exibição padrão.
  /// Se autoFullscreen estiver desativado (padrão), garante modo janela maximizada sem tela cheia exclusiva.
  static void initDefaultFullscreen() {
    if (isAutoFullscreen) {
      platform.initPlatformDefaultFullscreen();
    } else {
      exitFullscreen();
      maximize();
    }
  }

  /// Maximiza a janela na área de trabalho sem entrar em tela cheia exclusiva.
  static void maximize() {
    platform.maximizePlatformWindow();
  }

  /// Força a entrada em modo tela cheia.
  static void enterFullscreen() {
    platform.enterPlatformFullscreen();
  }

  /// Sai do modo tela cheia.
  static void exitFullscreen() {
    platform.exitPlatformFullscreen();
  }

  /// Alterna entre tela cheia e modo normal.
  static void toggleFullscreen() {
    platform.togglePlatformFullscreen();
  }

  /// Indica se a aplicação está em tela cheia no navegador/dispositivo.
  static bool get isFullscreen => platform.isPlatformFullscreen();

  /// Obtém a preferência salva de tela cheia por padrão.
  static bool get isAutoFullscreen => platform.getPlatformAutoFullscreen();

  /// Define a preferência de tela cheia e aplica imediatamente.
  static void setAutoFullscreen(bool enabled) {
    platform.setPlatformAutoFullscreen(enabled);
  }
}

