import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/services/auth_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/battle/presentation/screens/arena_screen.dart';
import '../../features/lobby/presentation/screens/game_lobby_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

/// Configuração do roteador declarativo com Route Guards reativos (OWASP A01:2025).
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: AuthService.instance,
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = AuthService.instance.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login';
    final isSettings = state.matchedLocation == '/settings';

    // Route Guard: Bloqueia acesso a rotas restritas se não autenticado (OWASP A01)
    // Permite /login e /settings mesmo desautenticado para ajuste prévio de áudio/vídeo
    if (!isLoggedIn) {
      return (isLoggingIn || isSettings) ? null : '/login';
    }

    // Se já autenticado e tentar acessar /login, redireciona ao Lobby
    if (isLoggingIn) {
      return '/lobby';
    }

    return null;
  },
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/lobby',
      name: 'lobby',
      builder: (context, state) => const GameLobbyScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/hub',
      name: 'hub',
      redirect: (context, state) => '/lobby',
    ),
    GoRoute(
      path: '/arena',
      name: 'arena',
      builder: (context, state) {
        final matchId = state.uri.queryParameters['matchId'] ??
            (state.extra is String ? state.extra as String : null);
        return ArenaScreen(matchId: matchId);
      },
    ),
  ],
);

