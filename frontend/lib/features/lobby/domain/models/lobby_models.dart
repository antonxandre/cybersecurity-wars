import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Modos de jogo selecionáveis no Lobby.
enum LobbyMode {
  createRoom,
  soloAi;

  String get title {
    switch (this) {
      case LobbyMode.createRoom:
        return 'CRIAR SALA (HOST)';
      case LobbyMode.soloAi:
        return 'TREINO TÁTICO VS IA';
    }
  }

  String get shortLabel {
    switch (this) {
      case LobbyMode.createRoom:
        return 'Criar Sala';
      case LobbyMode.soloAi:
        return 'Treino IA';
    }
  }

  String get description {
    switch (this) {
      case LobbyMode.createRoom:
        return 'Hospede uma sala dedicada em servidor seguro. Compartilhe o código de convite ou adicione aliados e adversários diretamente na sala.';
      case LobbyMode.soloAi:
        return 'Enfrente um bot scriptado com árvore de decisões adaptativa em mapa panorâmico contínuo. Aloque nós defensivos, mine recursos e neutralize ataques no grid adversário.';
    }
  }

  Color get accentColor {
    switch (this) {
      case LobbyMode.createRoom:
        return AppColors.blueTeam;
      case LobbyMode.soloAi:
        return AppColors.coreAi;
    }
  }

  IconData get icon {
    switch (this) {
      case LobbyMode.createRoom:
        return Icons.wifi_tethering_rounded;
      case LobbyMode.soloAi:
        return Icons.smart_toy_rounded;
    }
  }

  String get assetImage {
    switch (this) {
      case LobbyMode.createRoom:
        return 'assets/images/lobby_mode_create_room.jpg';
      case LobbyMode.soloAi:
        return 'assets/images/lobby_mode_solo_ai.jpg';
    }
  }
}

/// Dificuldades do bot na partida Solo.
enum AiDifficulty {
  recruta,
  operador,
  mestre;

  String get title {
    switch (this) {
      case AiDifficulty.recruta:
        return 'Recruta (Fácil)';
      case AiDifficulty.operador:
        return 'Operador (Médio)';
      case AiDifficulty.mestre:
        return 'Mestre (Especialista)';
    }
  }

  String get subtitle {
    switch (this) {
      case AiDifficulty.recruta:
        return 'IA passiva, foco em defesas simples e sondas leves.';
      case AiDifficulty.operador:
        return 'IA balanceada, recruta mineradores e envia SYN Floods.';
      case AiDifficulty.mestre:
        return 'IA agressiva, combos de Trojan e upgrades de Mainframe.';
    }
  }

  Color get color {
    switch (this) {
      case AiDifficulty.recruta:
        return AppColors.blueTeam;
      case AiDifficulty.operador:
        return AppColors.cpuClock;
      case AiDifficulty.mestre:
        return AppColors.redTeam;
    }
  }
}

/// Fases da animação / máquina de estados de Matchmaking.
enum MatchmakingPhase {
  idle,
  searching,
  found,
  launching;

  bool get isActive => this != MatchmakingPhase.idle;
}

/// Status de presença de um operador amigo.
enum FriendStatus {
  online,
  inMatch,
  away,
  offline;

  String get label {
    switch (this) {
      case FriendStatus.online:
        return 'Online';
      case FriendStatus.inMatch:
        return 'Em Partida';
      case FriendStatus.away:
        return 'Ausente';
      case FriendStatus.offline:
        return 'Offline';
    }
  }

  Color get color {
    switch (this) {
      case FriendStatus.online:
        return AppColors.bandwidth;
      case FriendStatus.inMatch:
        return AppColors.blueTeam;
      case FriendStatus.away:
        return AppColors.cpuClock;
      case FriendStatus.offline:
        return AppColors.textMuted;
    }
  }
}

/// Perfil de progressão e estatísticas do jogador logado.
class PlayerProfile {
  final int level;
  final int currentXp;
  final int xpToNext;
  final String rankName;
  final int rankTier;
  final int bits;
  final int tokens;
  final int wins;
  final int losses;
  final int matches;
  final int winStreak;
  final int totalPurges;

  const PlayerProfile({
    required this.level,
    required this.currentXp,
    required this.xpToNext,
    this.rankName = '',
    this.rankTier = 0,
    this.bits = 0,
    this.tokens = 0,
    required this.wins,
    int? losses,
    required this.matches,
    this.winStreak = 0,
    this.totalPurges = 0,
  }) : losses = losses ?? (matches >= wins ? matches - wins : 0);

  double get xpProgress => xpToNext > 0 ? (currentXp / xpToNext).clamp(0.0, 1.0) : 0.0;
  double get winRate => matches > 0 ? (wins / matches) * 100 : 0.0;
}

/// Amigo no painel social / party.
class LobbyFriend {
  final String id;
  final String name;
  final FriendStatus status;
  final int level;
  final String? activity;

  const LobbyFriend({
    required this.id,
    required this.name,
    required this.status,
    required this.level,
    this.activity,
  });

  bool get canInvite => status == FriendStatus.online;
}

/// Notícia / novidade tática no painel de novidades.
class LobbyNewsItem {
  final String tag;
  final String title;
  final String summary;
  final Color accentColor;
  final IconData icon;
  final String date;

  const LobbyNewsItem({
    required this.tag,
    required this.title,
    required this.summary,
    required this.accentColor,
    required this.icon,
    required this.date,
  });
}

/// Informações de sala pública ativa.
class PublicRoom {
  final String code;
  final String host;
  final String mode;
  final int players;
  final int maxPlayers;
  final int ping;
  final List<String> playerNames;

  const PublicRoom({
    required this.code,
    required this.host,
    required this.mode,
    required this.players,
    required this.maxPlayers,
    required this.ping,
    this.playerNames = const [],
  });

  bool get isFull => players >= maxPlayers;
  bool get hasSlots => players < maxPlayers;
  int get availableSlots => (maxPlayers - players).clamp(0, maxPlayers);

  Color get pingColor {
    if (ping < 50) return AppColors.bandwidth;
    if (ping < 100) return AppColors.cpuClock;
    return AppColors.redTeam;
  }

  PublicRoom copyWith({
    String? code,
    String? host,
    String? mode,
    int? players,
    int? maxPlayers,
    int? ping,
    List<String>? playerNames,
  }) {
    return PublicRoom(
      code: code ?? this.code,
      host: host ?? this.host,
      mode: mode ?? this.mode,
      players: players ?? this.players,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      ping: ping ?? this.ping,
      playerNames: playerNames ?? this.playerNames,
    );
  }
}

