// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;

bool _autoFullscreenListenerRegistered = false;

/// Inicializa o comportamento de tela cheia padrão na Web.
/// Como os navegadores exigem gesto do usuário para requestFullscreen(),
/// registramos ouvintes de primeiro toque/clique para disparar automaticamente
/// quando a preferência estiver ativa (padrão: true).
void initPlatformDefaultFullscreen() {
  if (_autoFullscreenListenerRegistered) return;
  _autoFullscreenListenerRegistered = true;

  final autoEnabled = getPlatformAutoFullscreen();
  if (!autoEnabled) return;

  void onFirstUserInteraction(html.Event event) {
    if (getPlatformAutoFullscreen()) {
      enterPlatformFullscreen();
    }
    // Remove os ouvintes após o primeiro disparo com sucesso ou falha
    html.window.removeEventListener('click', onFirstUserInteraction);
    html.window.removeEventListener('pointerdown', onFirstUserInteraction);
    html.window.removeEventListener('keydown', onFirstUserInteraction);
  }

  html.window.addEventListener('click', onFirstUserInteraction);
  html.window.addEventListener('pointerdown', onFirstUserInteraction);
  html.window.addEventListener('keydown', onFirstUserInteraction);
}

void enterPlatformFullscreen() {
  if (html.document.fullscreenElement == null) {
    try {
      html.document.documentElement?.requestFullscreen();
    } catch (_) {}
  }
}

void exitPlatformFullscreen() {
  if (html.document.fullscreenElement != null) {
    try {
      html.document.exitFullscreen();
    } catch (_) {}
  }
}

void maximizePlatformWindow() {
  // Na Web a aba do navegador já ocupa o espaço padrão; garante saída do modo tela cheia exclusivo
  exitPlatformFullscreen();
}

void togglePlatformFullscreen() {
  if (html.document.fullscreenElement != null) {
    exitPlatformFullscreen();
  } else {
    enterPlatformFullscreen();
  }
}

bool isPlatformFullscreen() {
  return html.document.fullscreenElement != null;
}

bool getPlatformAutoFullscreen() {
  final stored = html.window.localStorage['cyberwars_fullscreen'];
  // Padrão: true (ativado por padrão)
  return stored != 'false';
}

void setPlatformAutoFullscreen(bool enabled) {
  html.window.localStorage['cyberwars_fullscreen'] = enabled ? 'true' : 'false';
  if (enabled) {
    enterPlatformFullscreen();
  } else {
    exitPlatformFullscreen();
  }
}

