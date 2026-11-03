/// Modelo de preferências e configurações operacionais do PromptSec Arena.
class GameSettings {
  final bool fullscreenByDefault;
  final bool neonGlowEnabled;
  final bool animatedGridEnabled;
  final int targetFps;
  final double masterVolume;
  final double sfxVolume;
  final double bgmVolume;
  final bool hapticFeedback;
  final String promptDelimiter;
  final String tlsCipher;
  final bool logprobsTelemetry;
  final bool panoramicCamera;
  final bool quickBuild;
  final bool autoReadyZeroTurn;

  const GameSettings({
    this.fullscreenByDefault = true,
    this.neonGlowEnabled = true,
    this.animatedGridEnabled = true,
    this.targetFps = 60,
    this.masterVolume = 0.8,
    this.sfxVolume = 0.9,
    this.bgmVolume = 0.7,
    this.hapticFeedback = true,
    this.promptDelimiter = 'XML Boundary (<rules>)',
    this.tlsCipher = 'PQC (X25519MLKEM768)',
    this.logprobsTelemetry = true,
    this.panoramicCamera = true,
    this.quickBuild = false,
    this.autoReadyZeroTurn = false,
  });

  GameSettings copyWith({
    bool? fullscreenByDefault,
    bool? neonGlowEnabled,
    bool? animatedGridEnabled,
    int? targetFps,
    double? masterVolume,
    double? sfxVolume,
    double? bgmVolume,
    bool? hapticFeedback,
    String? promptDelimiter,
    String? tlsCipher,
    bool? logprobsTelemetry,
    bool? panoramicCamera,
    bool? quickBuild,
    bool? autoReadyZeroTurn,
  }) {
    return GameSettings(
      fullscreenByDefault: fullscreenByDefault ?? this.fullscreenByDefault,
      neonGlowEnabled: neonGlowEnabled ?? this.neonGlowEnabled,
      animatedGridEnabled: animatedGridEnabled ?? this.animatedGridEnabled,
      targetFps: targetFps ?? this.targetFps,
      masterVolume: masterVolume ?? this.masterVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
      bgmVolume: bgmVolume ?? this.bgmVolume,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      promptDelimiter: promptDelimiter ?? this.promptDelimiter,
      tlsCipher: tlsCipher ?? this.tlsCipher,
      logprobsTelemetry: logprobsTelemetry ?? this.logprobsTelemetry,
      panoramicCamera: panoramicCamera ?? this.panoramicCamera,
      quickBuild: quickBuild ?? this.quickBuild,
      autoReadyZeroTurn: autoReadyZeroTurn ?? this.autoReadyZeroTurn,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullscreenByDefault': fullscreenByDefault,
        'neonGlowEnabled': neonGlowEnabled,
        'animatedGridEnabled': animatedGridEnabled,
        'targetFps': targetFps,
        'masterVolume': masterVolume,
        'sfxVolume': sfxVolume,
        'bgmVolume': bgmVolume,
        'hapticFeedback': hapticFeedback,
        'promptDelimiter': promptDelimiter,
        'tlsCipher': tlsCipher,
        'logprobsTelemetry': logprobsTelemetry,
        'panoramicCamera': panoramicCamera,
        'quickBuild': quickBuild,
        'autoReadyZeroTurn': autoReadyZeroTurn,
      };

  factory GameSettings.fromJson(Map<String, dynamic> json) {
    return GameSettings(
      fullscreenByDefault: json['fullscreenByDefault'] as bool? ?? true,
      neonGlowEnabled: json['neonGlowEnabled'] as bool? ?? true,
      animatedGridEnabled: json['animatedGridEnabled'] as bool? ?? true,
      targetFps: (json['targetFps'] as num?)?.toInt() ?? 60,
      masterVolume: (json['masterVolume'] as num?)?.toDouble() ?? 0.8,
      sfxVolume: (json['sfxVolume'] as num?)?.toDouble() ?? 0.9,
      bgmVolume: (json['bgmVolume'] as num?)?.toDouble() ?? 0.7,
      hapticFeedback: json['hapticFeedback'] as bool? ?? true,
      promptDelimiter: json['promptDelimiter'] as String? ?? 'XML Boundary (<rules>)',
      tlsCipher: json['tlsCipher'] as String? ?? 'PQC (X25519MLKEM768)',
      logprobsTelemetry: json['logprobsTelemetry'] as bool? ?? true,
      panoramicCamera: json['panoramicCamera'] as bool? ?? true,
      quickBuild: json['quickBuild'] as bool? ?? false,
      autoReadyZeroTurn: json['autoReadyZeroTurn'] as bool? ?? false,
    );
  }
}
