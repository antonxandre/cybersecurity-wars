import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../auth/domain/services/auth_service.dart';
import '../domain/models/lobby_models.dart';
import 'lobby_mock_repository.dart';

/// Implementação do repositório do Lobby conectada aos endpoints REST do backend NestJS.
/// Mantém compatibilidade com fallback gracioso em caso de instabilidade de rede.
class LobbyApiRepository implements LobbyRepository {
  final LobbyMockRepository _fallback = const LobbyMockRepository();

  PlayerProfile? _cachedProfile;
  List<LobbyFriend>? _cachedFriends;
  List<LobbyNewsItem>? _cachedNews;
  List<PublicRoom> _cachedRooms = [];

  @override
  PlayerProfile getPlayerProfile() {
    return _cachedProfile ?? _fallback.getPlayerProfile();
  }

  @override
  List<LobbyFriend> getFriends() {
    return _cachedFriends ?? _fallback.getFriends();
  }

  @override
  List<LobbyNewsItem> getNews() {
    return _cachedNews ?? _fallback.getNews();
  }

  @override
  List<PublicRoom> getPublicRooms() {
    return List<PublicRoom>.from(_cachedRooms);
  }

  /// Busca o perfil atualizado do operador no endpoint `/api/users/profile`.
  Future<PlayerProfile> fetchProfile() async {
    final token = AuthService.instance.accessToken;
    if (token == null || token.isEmpty) {
      return getPlayerProfile();
    }

    try {
      final uri = ApiConfig.apiUrl('/users/profile');
      final res = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _cachedProfile = PlayerProfile.fromJson(data);
        return _cachedProfile!;
      }
    } catch (e) {
      debugPrint('[LobbyApiRepository] Erro ao buscar perfil: $e');
    }
    return getPlayerProfile();
  }

  /// Busca as notícias e cenários da API (`/api/scenarios` ou notícias ativas).
  Future<List<LobbyNewsItem>> fetchNews() async {
    try {
      final uri = ApiConfig.apiUrl('/scenarios');
      final res = await http.get(uri).timeout(const Duration(seconds: 4));

      if (res.statusCode == 200) {
        final List data = jsonDecode(res.body);
        if (data.isNotEmpty) {
          _cachedNews = data.map<LobbyNewsItem>((item) {
            return LobbyNewsItem(
              tag: item['category']?.toString().toUpperCase() ?? 'MISSÃO',
              title: item['title']?.toString() ?? 'Cenário Tático',
              summary: item['description']?.toString() ?? '',
              accentColor: AppColors.blueTeam,
              icon: _iconForCategory(item['category']?.toString()),
              date: 'Ativo',
            );
          }).toList();
          return _cachedNews!;
        }
      }
    } catch (e) {
      debugPrint('[LobbyApiRepository] Erro ao buscar cenários da API: $e');
    }
    return getNews();
  }

  /// Busca as salas ativas reais no backend (sem mock).
  Future<List<PublicRoom>> fetchPublicRooms() async {
    try {
      final uri = ApiConfig.apiUrl('/matches');
      final token = AuthService.instance.accessToken;
      final headers = {'Content-Type': 'application/json'};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }

      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        final dynamic data = jsonDecode(res.body);
        if (data is List) {
          _cachedRooms = data
              .map<PublicRoom>((m) => PublicRoom.fromJson(m as Map<String, dynamic>))
              .toList();
          return List<PublicRoom>.from(_cachedRooms);
        }
      }
    } catch (e) {
      debugPrint('[LobbyApiRepository] Erro ao buscar partidas: $e');
    }
    return List<PublicRoom>.from(_cachedRooms);
  }

  /// Cria uma nova sala/partida integrada à API do NestJS (`POST /api/matches`).
  @override
  Future<PublicRoom?> createRoom({
    String? scenarioId,
    String? customCode,
    bool is2v2 = true,
    String? mode,
  }) async {
    final token = AuthService.instance.accessToken;
    final uri = ApiConfig.apiUrl('/matches');
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    final effectiveCode = customCode?.trim().isNotEmpty == true ? customCode!.trim() : null;
    final payload = {
      'scenarioId': scenarioId ?? 'scenario-a',
      if (effectiveCode != null) 'customCode': effectiveCode,
      'is2v2': is2v2,
      'mode': mode ?? (is2v2 ? '2v2 Duplas' : '1v1 Duelo'),
      'joinAsTeam': 'BLUE_TEAM',
    };

    try {
      final res = await http
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 5));

      if (res.statusCode == 200 || res.statusCode == 201) {
        final data = jsonDecode(res.body);
        final newRoom = PublicRoom.fromJson(data);
        _cachedRooms.removeWhere((r) => r.code == newRoom.code);
        _cachedRooms.insert(0, newRoom);
        return newRoom;
      } else {
        debugPrint('[LobbyApiRepository] Erro ao criar sala na API: ${res.statusCode} ${res.body}');
      }
    } catch (e) {
      debugPrint('[LobbyApiRepository] Falha ao conectar na criação de sala: $e');
    }

    // Fallback gracioso local em caso de backend inacessível
    final fallbackCode = effectiveCode ?? 'ROOM-${DateTime.now().millisecondsSinceEpoch % 1000}';
    final fallbackHost = AuthService.instance.currentUser?.username ?? 'Você';
    final fallbackRoom = PublicRoom(
      code: fallbackCode,
      host: fallbackHost,
      mode: mode ?? (is2v2 ? '2v2 Duplas' : '1v1 Duelo'),
      players: 1,
      maxPlayers: is2v2 ? 4 : 2,
      ping: 20,
      playerNames: [fallbackHost],
    );
    _cachedRooms.removeWhere((r) => r.code == fallbackRoom.code);
    _cachedRooms.insert(0, fallbackRoom);
    return fallbackRoom;
  }

  /// Ingressa em uma sala via API do NestJS (`POST /api/matches/:id/join`).
  @override
  Future<bool> joinRoom(String roomId, {String? team}) async {
    final token = AuthService.instance.accessToken;
    final uri = ApiConfig.apiUrl('/matches/$roomId/join');
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await http
          .post(
            uri,
            headers: headers,
            body: jsonEncode({'team': team ?? 'RED_TEAM'}),
          )
          .timeout(const Duration(seconds: 4));

      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[LobbyApiRepository] Erro ao ingressar na partida: $e');
      return false;
    }
  }

  /// Inicia a partida via API do NestJS (`POST /api/matches/:id/start`).
  @override
  Future<bool> startMatch(String roomId) async {
    final token = AuthService.instance.accessToken;
    final uri = ApiConfig.apiUrl('/matches/$roomId/start');
    final headers = {'Content-Type': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    try {
      final res = await http.post(uri, headers: headers).timeout(const Duration(seconds: 4));
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[LobbyApiRepository] Erro ao iniciar partida: $e');
      return false;
    }
  }

  static IconData _iconForCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'llmprompt':
      case 'prompt':
        return Icons.psychology_rounded;
      case 'hybridcitadel':
      case 'hybrid':
        return Icons.hub_rounded;
      case 'vpnmitm':
      case 'vpn':
        return Icons.vpn_lock_rounded;
      default:
        return Icons.shield_rounded;
    }
  }
}
