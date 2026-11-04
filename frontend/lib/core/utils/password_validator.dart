import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Item de validação de critério de segurança de senha tática.
class PasswordRequirement {
  final String label;
  final bool isMet;

  const PasswordRequirement({
    required this.label,
    required this.isMet,
  });
}

/// Nível de solidez criptográfica da senha.
enum PasswordSecurityLevel {
  critical,
  weak,
  moderate,
  strong,
  armored,
}

/// Resultado detalhado da análise de solidez de senha (OWASP A07).
class PasswordStrengthResult {
  final String password;
  final int score;
  final double progress;
  final PasswordSecurityLevel level;
  final String label;
  final Color color;
  final List<PasswordRequirement> requirements;
  final bool isValid;
  final String? errorMessage;

  const PasswordStrengthResult({
    required this.password,
    required this.score,
    required this.progress,
    required this.level,
    required this.label,
    required this.color,
    required this.requirements,
    required this.isValid,
    this.errorMessage,
  });
}

/// Mecanismo centralizado de validação e análise de senhas táticas (OWASP Top 10 A07:2025).
class PasswordValidator {
  PasswordValidator._();

  static final RegExp _upperRegex = RegExp(r'[A-Z]');
  static final RegExp _lowerRegex = RegExp(r'[a-z]');
  static final RegExp _digitRegex = RegExp(r'[0-9]');
  static final RegExp _specialRegex = RegExp(r'[^a-zA-Z0-9\s]');

  /// Avalia a força da senha em tempo real e retorna métricas detalhadas.
  static PasswordStrengthResult analyze(String password) {
    final clean = password.trim();

    final hasMinLength = clean.length >= 8;
    final hasUpper = _upperRegex.hasMatch(clean);
    final hasLower = _lowerRegex.hasMatch(clean);
    final hasDigit = _digitRegex.hasMatch(clean);
    final hasSpecial = _specialRegex.hasMatch(clean);

    final requirements = [
      PasswordRequirement(
        label: 'Mínimo de 8 caracteres',
        isMet: hasMinLength,
      ),
      PasswordRequirement(
        label: 'Letra maiúscula (A-Z)',
        isMet: hasUpper,
      ),
      PasswordRequirement(
        label: 'Letra minúscula (a-z)',
        isMet: hasLower,
      ),
      PasswordRequirement(
        label: 'Número (0-9)',
        isMet: hasDigit,
      ),
      PasswordRequirement(
        label: 'Símbolo especial (!@#\$%^&*)',
        isMet: hasSpecial,
      ),
    ];

    int score = 0;
    if (hasMinLength) score++;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasDigit) score++;
    if (hasSpecial) score++;

    final isValid = hasMinLength && hasUpper && hasLower && hasDigit && hasSpecial;

    PasswordSecurityLevel level;
    String label;
    Color color;

    switch (score) {
      case 0:
      case 1:
        level = PasswordSecurityLevel.critical;
        label = 'CRÍTICA / VULNERÁVEL';
        color = AppColors.redTeam;
        break;
      case 2:
        level = PasswordSecurityLevel.weak;
        label = 'FRACA';
        color = AppColors.bastionFirewall;
        break;
      case 3:
        level = PasswordSecurityLevel.moderate;
        label = 'MÉDIA';
        color = AppColors.cpuClock;
        break;
      case 4:
        level = PasswordSecurityLevel.strong;
        label = 'FORTE';
        color = AppColors.blueTeam;
        break;
      case 5:
      default:
        level = PasswordSecurityLevel.armored;
        label = 'BLINDADA (OWASP A07)';
        color = AppColors.bandwidth;
        break;
    }

    String? error;
    if (clean.isEmpty) {
      error = 'A senha é obrigatória.';
    } else if (clean.length > 128) {
      error = 'A senha não pode exceder 128 caracteres.';
    } else if (!isValid) {
      final missing = requirements.where((r) => !r.isMet).map((r) => r.label).toList();
      error = 'Requisitos pendentes: ${missing.join(", ")}.';
    }

    return PasswordStrengthResult(
      password: clean,
      score: score,
      progress: (score / 5.0).clamp(0.0, 1.0),
      level: level,
      label: label,
      color: color,
      requirements: requirements,
      isValid: isValid && clean.length <= 128,
      errorMessage: error,
    );
  }

  /// Validação rápida pré-envio para formulário de login (prevenção de DoS e requisições vazias).
  static ({bool isValid, String? errorMessage}) validateLogin(String password) {
    final clean = password.trim();
    if (clean.isEmpty) {
      return (isValid: false, errorMessage: 'Digite a sua senha.');
    }
    if (clean.length < 8) {
      return (
        isValid: false,
        errorMessage: 'A senha deve possuir pelo menos 8 caracteres.',
      );
    }
    if (clean.length > 128) {
      return (
        isValid: false,
        errorMessage: 'A senha excede o limite máximo permitido de 128 caracteres.',
      );
    }
    return (isValid: true, errorMessage: null);
  }
}
