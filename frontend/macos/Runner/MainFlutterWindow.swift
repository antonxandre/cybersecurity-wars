import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)

    RegisterGeneratedPlugins(registry: flutterViewController)

    // Habilitar suporte nativo a Tela Cheia (AppKit Full Screen Primary)
    self.collectionBehavior.insert(.fullScreenPrimary)

    // MethodChannel para controle de Fullscreen e Janela nativa no macOS
    let windowChannel = FlutterMethodChannel(
      name: "promptsec.arena/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )

    windowChannel.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else {
        result(nil)
        return
      }

      switch call.method {
      case "enterFullscreen":
        if !self.styleMask.contains(.fullScreen) {
          self.toggleFullScreen(nil)
        }
        result(true)
      case "exitFullscreen":
        if self.styleMask.contains(.fullScreen) {
          self.toggleFullScreen(nil)
        }
        result(false)
      case "toggleFullscreen":
        self.toggleFullScreen(nil)
        result(self.styleMask.contains(.fullScreen))
      case "maximize":
        if self.styleMask.contains(.fullScreen) {
          self.toggleFullScreen(nil)
        }
        if let screen = self.screen ?? NSScreen.main {
          self.setFrame(screen.visibleFrame, display: true)
        } else if !self.isZoomed {
          self.zoom(nil)
        }
        result(true)
      case "isFullscreen":
        result(self.styleMask.contains(.fullScreen))
      default:
        result(FlutterMethodNotImplemented)
      }
    }

    super.awakeFromNib()

    // Inicializa a janela maximizada (ocupando o espaço visível da tela)
    DispatchQueue.main.async { [weak self] in
      guard let self = self else { return }
      if let screen = self.screen ?? NSScreen.main {
        self.setFrame(screen.visibleFrame, display: true)
      }
    }
  }
}

