import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/domain/services/auth_service.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/battle/presentation/screens/arena_screen.dart';
import '../../features/scenarios/presentation/screens/scenario_hub_screen.dart';

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

    // Se já autenticado e tentar acessar /login, redireciona ao Hub
    if (isLoggingIn) {
      return '/hub';
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
      path: '/hub',
      name: 'hub',
      builder: (context, state) => const ScenarioHubScreen(),
    ),
    GoRoute(
      path: '/arena',
      name: 'arena',
      builder: (context, state) {
        // Suporta passagem de cenário selecionado via extra ou query params
        return const ArenaScreen();
      },
    ),
  ],
);
