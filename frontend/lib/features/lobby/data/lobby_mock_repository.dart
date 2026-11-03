import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../domain/models/lobby_models.dart';

/// Contrato para o repositório de dados do Lobby.
abstract class LobbyRepository {
  PlayerProfile getPlayerProfile();
  List<LobbyFriend> getFriends();
  List<LobbyNewsItem> getNews();
  List<PublicRoom> getPublicRooms();
  Future<PublicRoom?> createRoom({
    String? scenarioId,
    String? customCode,
    bool is2v2 = true,
    String? mode,
  });
  Future<bool> joinRoom(String roomId, {String? team});
}

/// Implementação do repositório para testes unitários e fallback local controlado.
class LobbyMockRepository implements LobbyRepository {
  final List<LobbyFriend> initialFriends;
  final List<PublicRoom> initialRooms;

  const LobbyMockRepository({
    this.initialFriends = const [],
    this.initialRooms = const [],
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
    return List<PublicRoom>.from(initialRooms);
  }

  @override
  Future<PublicRoom?> createRoom({
    String? scenarioId,
    String? customCode,
    bool is2v2 = true,
    String? mode,
  }) async {
    final code = customCode?.trim().isNotEmpty == true ? customCode!.trim() : 'ROOM-01';
    return PublicRoom(
      code: code,
      host: 'Você',
      mode: mode ?? (is2v2 ? '2v2 Duplas' : '1v1 Duelo'),
      players: 1,
      maxPlayers: is2v2 ? 4 : 2,
      ping: 15,
      playerNames: const ['Você'],
    );
  }

  @override
  Future<bool> joinRoom(String roomId, {String? team}) async {
    return true;
  }
}
