import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/models/lobby_models.dart';

/// Contrato para o repositório de dados do Lobby.
abstract class LobbyRepository {
  PlayerProfile getPlayerProfile();
  List<LobbyFriend> getFriends();
  List<LobbyNewsItem> getNews();
  List<PublicRoom> getPublicRooms();
}

/// Implementação mockada local para o client de jogo (pronta para substituição por NestJS API).
class LobbyMockRepository implements LobbyRepository {
  final List<LobbyFriend> initialFriends;

  const LobbyMockRepository({
    this.initialFriends = const [],
  });

  @override
  PlayerProfile getPlayerProfile() {
    return const PlayerProfile(
      level: 42,
      currentXp: 3820,
      xpToNext: 5000,
      wins: 128,
      losses: 56,
      matches: 184,
      winStreak: 5,
      totalPurges: 412,
    );
  }

  @override
  List<LobbyFriend> getFriends() {
    return List<LobbyFriend>.from(initialFriends);
  }

  @override
  List<LobbyNewsItem> getNews() {
    return const [
      LobbyNewsItem(
        tag: 'PATCH 1.4',
        title: 'NOVOS MALWARES & BALANCEAMENTO',
        summary:
            'Trabalhamos no balanceamento do Trojan Horse e introduzimos a nova unidade Ransomware Encryptor no modo Legion TD.',
        accentColor: AppColors.blueTeam,
        icon: Icons.auto_awesome_rounded,
        date: 'Hoje',
      ),
      LobbyNewsItem(
        tag: 'EVENTO',
        title: 'TORNEIO CYBER GUARDIAN 2026',
        summary:
            'Participe das eliminatórias no próximo fim de semana. Dobre sua taxa de Tokens em vitórias no modo 2v2!',
        accentColor: AppColors.cpuClock,
        icon: Icons.emoji_events_rounded,
        date: 'Nesta Sexta',
      ),
      LobbyNewsItem(
        tag: 'TEMPORADA',
        title: 'RESET DE RANKING GLOBAL',
        summary:
            'A temporada Zero-Day está chegando ao fim. Garanta suas recompensas exclusivas do elo Diamante.',
        accentColor: AppColors.redTeam,
        icon: Icons.shield_rounded,
        date: 'Faltam 5 dias',
      ),
    ];
  }

  @override
  List<PublicRoom> getPublicRooms() {
    return const [
      PublicRoom(
        code: 'CYB-709',
        host: 'ZeroDay_Hunter',
        mode: '2v2 Duplas',
        players: 3,
        maxPlayers: 4,
        ping: 18,
        playerNames: ['ZeroDay_Hunter', 'BitShifter', 'NullPointer'],
      ),
      PublicRoom(
        code: 'NET-404',
        host: 'SynFlood_Master',
        mode: '1v1 Duelo',
        players: 1,
        maxPlayers: 2,
        ping: 24,
        playerNames: ['SynFlood_Master'],
      ),
      PublicRoom(
        code: 'SEC-888',
        host: 'KernelPanic',
        mode: '2v2 Duplas',
        players: 4,
        maxPlayers: 4,
        ping: 32,
        playerNames: ['KernelPanic', 'ShadowByte', 'FirewallGod', 'RootAccess'],
      ),
      PublicRoom(
        code: 'PRO-101',
        host: 'ByteDefender',
        mode: '1v1 Duelo',
        players: 2,
        maxPlayers: 2,
        ping: 15,
        playerNames: ['ByteDefender', 'CiscoNinja'],
      ),
      PublicRoom(
        code: 'APT-029',
        host: 'CipherGhost',
        mode: '2v2 Duplas',
        players: 1,
        maxPlayers: 4,
        ping: 48,
        playerNames: ['CipherGhost'],
      ),
      PublicRoom(
        code: 'EXP-999',
        host: 'Overclocked',
        mode: '1v1 Duelo',
        players: 1,
        maxPlayers: 2,
        ping: 112,
        playerNames: ['Overclocked'],
      ),
    ];
  }
}
