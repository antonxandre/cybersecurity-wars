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

  factory PlayerProfile.fromJson(Map<String, dynamic> json) {
    final matchesCount = (json['matches'] as num?)?.toInt() ?? 0;
    final winsCount = (json['wins'] as num?)?.toInt() ?? 0;
    final lossesCount = (json['losses'] as num?)?.toInt();

    return PlayerProfile(
      level: (json['level'] as num?)?.toInt() ?? 1,
      currentXp: (json['currentXp'] as num?)?.toInt() ?? (json['xp'] as num?)?.toInt() ?? 0,
      xpToNext: (json['xpToNext'] as num?)?.toInt() ?? 1000,
      wins: winsCount,
      losses: lossesCount,
      matches: matchesCount,
      winStreak: (json['winStreak'] as num?)?.toInt() ?? 0,
      totalPurges: (json['totalPurges'] as num?)?.toInt() ??
          (json['attacksNeutralized'] as num?)?.toInt() ??
          (json['score'] as num?)?.toInt() ??
          0,
      bits: (json['bits'] as num?)?.toInt() ?? 0,
      tokens: (json['tokens'] as num?)?.toInt() ?? 0,
    );
  }
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
  final String status;

  const PublicRoom({
    required this.code,
    required this.host,
    required this.mode,
    required this.players,
    required this.maxPlayers,
    required this.ping,
    this.playerNames = const [],
    this.status = 'WAITING',
  });

  bool get isFull => players >= maxPlayers;
  bool get hasSlots => players < maxPlayers;
  bool get isInProgress => status == 'IN_PROGRESS';
  int get availableSlots => (maxPlayers - players).clamp(0, maxPlayers);

  factory PublicRoom.fromJson(Map<String, dynamic> json) {
    final code = json['code']?.toString() ?? json['id']?.toString() ?? '';
    final blueUsername = json['bluePlayer'] is Map ? json['bluePlayer']['username']?.toString() : null;
    final redUsername = json['redPlayer'] is Map ? json['redPlayer']['username']?.toString() : null;
    final castersList = json['casters'] is List
        ? (json['casters'] as List)
            .map((c) => c is Map ? c['username']?.toString() : null)
            .whereType<String>()
            .toList()
        : <String>[];

    final playerNames = (json['playerNames'] as List?)?.map((e) => e.toString()).toList() ??
        [
          if (blueUsername != null) blueUsername,
          if (redUsername != null) redUsername,
          ...castersList,
        ];

    final host = json['host']?.toString() ??
        json['hostUsername']?.toString() ??
        blueUsername ??
        redUsername ??
        (castersList.isNotEmpty ? castersList.first : 'Host');

    final mode = json['mode']?.toString() ??
        json['scenarioTitle']?.toString() ??
        '2v2 Duplas';

    final maxPlayers = (json['maxPlayers'] as num?)?.toInt() ??
        (mode.contains('2v2') ? 4 : 2);

    final players = (json['players'] as num?)?.toInt() ??
        (json['playersCount'] as num?)?.toInt() ??
        playerNames.length;

    final status = json['status']?.toString() ?? 'WAITING';

    return PublicRoom(
      code: code,
      host: host,
      mode: mode,
      players: players > 0 ? players : 1,
      maxPlayers: maxPlayers,
      ping: (json['ping'] as num?)?.toInt() ?? 20,
      playerNames: playerNames.isNotEmpty ? playerNames : [host],
      status: status,
    );
  }

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
    String? status,
  }) {
    return PublicRoom(
      code: code ?? this.code,
      host: host ?? this.host,
      mode: mode ?? this.mode,
      players: players ?? this.players,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      ping: ping ?? this.ping,
      playerNames: playerNames ?? this.playerNames,
      status: status ?? this.status,
    );
  }
}

