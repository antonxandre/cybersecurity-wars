import 'fullscreen_helper_stub.dart'
    if (dart.library.html) 'fullscreen_helper_web.dart' as platform;

/// Utilitário multi-plataforma para alternância de modo Fullscreen (Web, Mobile, Desktop).
class FullscreenHelper {
  FullscreenHelper._();

  /// Alterna entre tela cheia e modo normal.
  static void toggleFullscreen() {
    platform.togglePlatformFullscreen();
  }

  /// Indica se a aplicação está em tela cheia no navegador.
  static bool get isFullscreen => platform.isPlatformFullscreen();
}
