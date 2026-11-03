import 'package:flutter_test/flutter_test.dart';
import 'package:promptsec_arena_front/features/settings/domain/models/game_settings.dart';
import 'package:promptsec_arena_front/features/settings/domain/services/settings_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('GameSettings Model Tests', () {
    test('Default values must have fullscreen enabled and balanced audio/graphics', () {
      const settings = GameSettings();
      expect(settings.fullscreenByDefault, isTrue);
      expect(settings.neonGlowEnabled, isTrue);
      expect(settings.animatedGridEnabled, isTrue);
      expect(settings.targetFps, equals(60));
      expect(settings.masterVolume, equals(0.8));
      expect(settings.sfxVolume, equals(0.9));
      expect(settings.bgmVolume, equals(0.7));
      expect(settings.tlsCipher, contains('PQC'));
      expect(settings.promptDelimiter, contains('XML'));
    });

    test('JSON serialization round-trip retains all configuration fields', () {
      const original = GameSettings(
        fullscreenByDefault: false,
        neonGlowEnabled: false,
        animatedGridEnabled: false,
        targetFps: 120,
        masterVolume: 0.5,
        sfxVolume: 0.6,
        bgmVolume: 0.4,
        hapticFeedback: false,
        promptDelimiter: 'JSON Schema Strict',
        tlsCipher: 'TLS 1.3 (ChaCha20-Poly1305)',
        logprobsTelemetry: false,
        panoramicCamera: false,
        quickBuild: true,
        autoReadyZeroTurn: true,
      );

      final json = original.toJson();
      final restored = GameSettings.fromJson(json);

      expect(restored.fullscreenByDefault, isFalse);
      expect(restored.neonGlowEnabled, isFalse);
      expect(restored.animatedGridEnabled, isFalse);
      expect(restored.targetFps, equals(120));
      expect(restored.masterVolume, equals(0.5));
      expect(restored.promptDelimiter, equals('JSON Schema Strict'));
      expect(restored.quickBuild, isTrue);
    });

    test('copyWith updates individual properties immutably', () {
      const original = GameSettings();
      final updated = original.copyWith(targetFps: 30, fullscreenByDefault: false);

      expect(updated.targetFps, equals(30));
      expect(updated.fullscreenByDefault, isFalse);
      expect(updated.masterVolume, equals(original.masterVolume));
    });
  });

  group('SettingsService Singleton Tests', () {
    test('Service initializes with default settings and updates cleanly', () {
      final service = SettingsService.instance;
      service.initialize();

      expect(service.isInitialized, isTrue);
      expect(service.settings.fullscreenByDefault, isTrue);

      bool notified = false;
      void listener() {
        notified = true;
      }

      service.addListener(listener);

      service.setMasterVolume(0.42);
      expect(service.settings.masterVolume, closeTo(0.42, 0.001));
      expect(notified, isTrue);

      service.setTargetFps(120);
      expect(service.settings.targetFps, equals(120));

      service.resetToDefaults();
      expect(service.settings.fullscreenByDefault, isTrue);
      expect(service.settings.masterVolume, equals(0.8));

      service.removeListener(listener);
    });
  });
}
