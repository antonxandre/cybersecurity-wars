import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/services/auth_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/battle/presentation/screens/arena_screen.dart';
import '../../features/lobby/presentation/screens/game_lobby_screen.dart';

/// Configuração do roteador declarativo com Route Guards reativos (OWASP A01:2025).
final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  refreshListenable: AuthService.instance,
  redirect: (BuildContext context, GoRouterState state) {
    final isLoggedIn = AuthService.instance.isAuthenticated;
    final isLoggingIn = state.matchedLocation == '/login';

    // Route Guard: Bloqueia acesso a rotas restritas se não autenticado (OWASP A01)
    if (!isLoggedIn) {
      return isLoggingIn ? null : '/login';
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
      path: '/hub',
      name: 'hub',
      redirect: (context, state) => '/lobby',
    ),
    GoRoute(
      path: '/arena',
      name: 'arena',
      builder: (context, state) {
        return const ArenaScreen();
      },
    ),
  ],
);
