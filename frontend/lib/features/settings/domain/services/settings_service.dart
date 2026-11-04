import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../../core/utils/fullscreen_helper.dart';
import '../models/game_settings.dart';
import 'settings_storage_stub.dart'
    if (dart.library.html) 'settings_storage_web.dart' as storage;

/// Serviço central de gerenciamento e persistência das configurações da Arena.
class SettingsService extends ChangeNotifier {
  static final SettingsService instance = SettingsService._internal();
  SettingsService._internal();

  static const String _storageKey = 'promptsec_arena_settings';

  GameSettings _settings = const GameSettings();
  bool _initialized = false;

  GameSettings get settings => _settings;
  bool get isInitialized => _initialized;

  /// Inicializa e carrega as preferências salvas localmente
  void initialize() {
    if (_initialized) return;
    _initialized = true;

    try {
      final raw = storage.readStorageString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(raw);
        _settings = GameSettings.fromJson(data);
      }
    } catch (e) {
      debugPrint('[SettingsService] Erro ao carregar configurações: $e');
      _settings = const GameSettings();
    }

    // Sincroniza preferência de tela cheia com FullscreenHelper
    if (_settings.fullscreenByDefault) {
      FullscreenHelper.setAutoFullscreen(true);
    } else {
      FullscreenHelper.exitFullscreen();
      FullscreenHelper.maximize();
    }
    notifyListeners();
  }

  void _persist() {
    try {
      final jsonStr = jsonEncode(_settings.toJson());
      storage.writeStorageString(_storageKey, jsonStr);
    } catch (e) {
      debugPrint('[SettingsService] Erro ao salvar configurações: $e');
    }
  }

  void updateSettings(GameSettings newSettings) {
    final oldFullscreen = _settings.fullscreenByDefault;
    _settings = newSettings;
    _persist();

    if (oldFullscreen != newSettings.fullscreenByDefault) {
      FullscreenHelper.setAutoFullscreen(newSettings.fullscreenByDefault);
    }

    notifyListeners();
  }

  void setFullscreenByDefault(bool enabled) {
    _settings = _settings.copyWith(fullscreenByDefault: enabled);
    _persist();
    FullscreenHelper.setAutoFullscreen(enabled);
    notifyListeners();
  }

  void setNeonGlow(bool enabled) {
    _settings = _settings.copyWith(neonGlowEnabled: enabled);
    _persist();
    notifyListeners();
  }

  void setAnimatedGrid(bool enabled) {
    _settings = _settings.copyWith(animatedGridEnabled: enabled);
    _persist();
    notifyListeners();
  }

  void setTargetFps(int fps) {
    _settings = _settings.copyWith(targetFps: fps);
    _persist();
    notifyListeners();
  }

  void setMasterVolume(double vol) {
    _settings = _settings.copyWith(masterVolume: vol.clamp(0.0, 1.0));
    _persist();
    notifyListeners();
  }

  void setSfxVolume(double vol) {
    _settings = _settings.copyWith(sfxVolume: vol.clamp(0.0, 1.0));
    _persist();
    notifyListeners();
  }

  void setBgmVolume(double vol) {
    _settings = _settings.copyWith(bgmVolume: vol.clamp(0.0, 1.0));
    _persist();
    notifyListeners();
  }

  void setHapticFeedback(bool enabled) {
    _settings = _settings.copyWith(hapticFeedback: enabled);
    _persist();
    notifyListeners();
  }

  void setPromptDelimiter(String delimiter) {
    _settings = _settings.copyWith(promptDelimiter: delimiter);
    _persist();
    notifyListeners();
  }

  void setTlsCipher(String cipher) {
    _settings = _settings.copyWith(tlsCipher: cipher);
    _persist();
    notifyListeners();
  }

  void setLogprobsTelemetry(bool enabled) {
    _settings = _settings.copyWith(logprobsTelemetry: enabled);
    _persist();
    notifyListeners();
  }

  void setPanoramicCamera(bool enabled) {
    _settings = _settings.copyWith(panoramicCamera: enabled);
    _persist();
    notifyListeners();
  }

  void setQuickBuild(bool enabled) {
    _settings = _settings.copyWith(quickBuild: enabled);
    _persist();
    notifyListeners();
  }

  void setAutoReadyZeroTurn(bool enabled) {
    _settings = _settings.copyWith(autoReadyZeroTurn: enabled);
    _persist();
    notifyListeners();
  }

  void resetToDefaults() {
    _settings = const GameSettings();
    _persist();
    FullscreenHelper.setAutoFullscreen(false);
    FullscreenHelper.exitFullscreen();
    notifyListeners();
  }
}
