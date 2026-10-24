import 'package:flutter/material.dart';

/// Paleta de cores e tokens visuais do PromptSec Arena (Cyberpunk High-Tech Neon).
class AppColors {
  AppColors._();

  // Fundo e Superfícies
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF121826);
  static const Color cardSurface = Color(0xFF182234);
  static const Color border = Color(0xFF1F293D);
  static const Color borderGlow = Color(0xFF2A3B57);

  // Blue Team (Defesa & Criptografia)
  static const Color blueTeam = Color(0xFF00F0FF);
  static const Color blueTeamSecondary = Color(0xFF0077FE);
  static const Color blueTeamGlow = Color(0x6600F0FF);

  // Red Team (Ataque & Exploits)
  static const Color redTeam = Color(0xFFFF3366);
  static const Color redTeamSecondary = Color(0xFFFF5500);
  static const Color redTeamGlow = Color(0x66FF3366);

  // Inteligência Artificial & LLM Core
  static const Color coreAi = Color(0xFFBD00FF);
  static const Color coreAiSecondary = Color(0xFF7928CA);
  static const Color coreAiGlow = Color(0x66BD00FF);

  // Recursos de Partida e Economia Legion TD
  static const Color bandwidth = Color(0xFF00FF66); // Banda de Rede (Mana/Energia)
  static const Color bandwidthGlow = Color(0x6600FF66);
  static const Color cpuClock = Color(0xFFFFCC00); // Clock/CPU Cycles (Economia)
  static const Color cpuClockGlow = Color(0x66FFCC00);
  static const Color bitsGold = Color(0xFFFFCC00); // Bits (Ouro no Legion TD)
  static const Color tokensLumber = Color(0xFFBD00FF); // Tokens (Cripto/Lumber no Legion TD)
  static const Color tokensLumberGlow = Color(0x66BD00FF);

  // Alertas e Status de Rede
  static const Color statusOpen = Color(0xFFFF3366); // Aberta / Perigo
  static const Color statusRestricted = Color(0xFFFFCC00); // Restrita IP
  static const Color statusClosed = Color(0xFF00F0FF); // Fechada / Protegida
  static const Color statusRedirect = Color(0xFFBD00FF); // 301 Redirect

  // Tipografia
  static const Color textPrimary = Color(0xFFF0F6FC);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF484F58);

  // Gradientes Táticos
  static const LinearGradient blueGradient = LinearGradient(
    colors: [blueTeam, blueTeamSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient redGradient = LinearGradient(
    colors: [redTeam, redTeamSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [coreAi, coreAiSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient bandwidthGradient = LinearGradient(
    colors: [bandwidth, Color(0xFF00B347)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Sombras Neon Glow
  static List<BoxShadow> neonGlow(Color color, {double blur = 12, double spread = 1}) {
    return [
      BoxShadow(
        color: color.withOpacity(0.5),
        blurRadius: blur,
        spreadRadius: spread,
      ),
    ];
  }
}
