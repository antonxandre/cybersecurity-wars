import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

enum UserRole { redTeam, blueTeam, caster, admin }

extension UserRoleX on UserRole {
  String get displayName {
    switch (this) {
      case UserRole.blueTeam:
        return 'Blue Team';
      case UserRole.redTeam:
        return 'Red Team';
      case UserRole.caster:
        return 'Caster';
      case UserRole.admin:
        return 'Admin';
    }
  }
}

/// Modelo imutável de Usuário Autenticado na plataforma.
class AuthUser {
  final String id;
  final String email;
  final String username;
  final UserRole role;

  const AuthUser({
    required this.id,
    required this.email,
    required this.username,
    required this.role,
  });

  bool get isBlueTeam => role == UserRole.blueTeam;
  bool get isRedTeam => role == UserRole.redTeam;

  Color get teamColor => isBlueTeam ? AppColors.blueTeam : AppColors.redTeam;

  String get roleDisplayName {
    switch (role) {
      case UserRole.blueTeam:
        return 'BLUE TEAM (DEFESA)';
      case UserRole.redTeam:
        return 'RED TEAM (ATAQUE)';
      case UserRole.caster:
        return 'CASTER / OBSERVER';
      case UserRole.admin:
        return 'SYSADMIN';
    }
  }

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    UserRole parsedRole = UserRole.blueTeam;
    final roleStr = json['role']?.toString().toUpperCase() ?? '';
    if (roleStr.contains('RED')) {
      parsedRole = UserRole.redTeam;
    } else if (roleStr.contains('CASTER')) {
      parsedRole = UserRole.caster;
    } else if (roleStr.contains('ADMIN')) {
      parsedRole = UserRole.admin;
    }

    return AuthUser(
      id: json['id']?.toString() ?? 'usr_local',
      email: json['email']?.toString() ?? 'operador@promptsec.arena',
      username: json['username']?.toString() ?? 'Operador Tático',
      role: parsedRole,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'username': username,
        'role': role.name,
      };
}
