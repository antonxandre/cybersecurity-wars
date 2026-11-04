import 'package:flutter/foundation.dart';

/// Configuração centralizada de endpoints e infraestrutura de rede da Cyber Arena.
/// Suporta injeção de ambiente via `--dart-define=API_BASE_URL=...` e `--dart-define=WS_URL=...`,
/// com detecção automática de origem em navegadores (Flutter Web).
class ApiConfig {
  ApiConfig._();

  static const String _envApiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String _envWsUrl = String.fromEnvironment('WS_URL');

  /// Prefixo global configurado no backend NestJS (app.setGlobalPrefix('api'))
  static const String apiPrefix = '/api';

  /// Retorna a URL base HTTP da API (ex: 'https://arena.exemplo.com' ou 'http://localhost:3000')
  static String get baseUrl {
    if (_envApiBaseUrl.isNotEmpty) {
      return _envApiBaseUrl.endsWith('/')
          ? _envApiBaseUrl.substring(0, _envApiBaseUrl.length - 1)
          : _envApiBaseUrl;
    }

    if (kIsWeb) {
      final origin = Uri.base.origin;
      // Se estiver rodando em porta de desenvolvimento do Flutter (ex: 8080 ou 5000+),
      // e o backend normalmente roda na 3000 em localhost:
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        return 'http://localhost:3000';
      }
      // Em produção na nuvem (Nginx servindo Flutter + API na mesma origem):
      return origin;
    }

    return 'http://localhost:3000';
  }

  /// Constrói a URL completa para um endpoint REST incluindo o prefixo `/api`
  /// Exemplo: `ApiConfig.apiUrl('/auth/login')` -> `http://localhost:3000/api/auth/login`
  static Uri apiUrl(String path, [Map<String, dynamic>? queryParameters]) {
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullPath =
        cleanPath.startsWith(apiPrefix) ? cleanPath : '$apiPrefix$cleanPath';

    final base = Uri.parse(baseUrl);
    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: fullPath,
      queryParameters: queryParameters,
    );
  }

  /// Retorna a URL base do WebSocket Gateway
  /// Exemplo: 'wss://arena.exemplo.com' ou 'ws://localhost:3000'
  static String get wsBaseUrl {
    if (_envWsUrl.isNotEmpty) {
      return _envWsUrl.endsWith('/')
          ? _envWsUrl.substring(0, _envWsUrl.length - 1)
          : _envWsUrl;
    }

    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.contains('localhost') || origin.contains('127.0.0.1')) {
        return 'ws://localhost:3000';
      }

      final uri = Uri.parse(origin);
      final wsScheme = uri.scheme == 'https' ? 'wss' : 'ws';
      final portSuffix = uri.hasPort ? ':${uri.port}' : '';
      return '$wsScheme://${uri.host}$portSuffix';
    }

    return 'ws://localhost:3000';
  }

  /// Retorna a URI para um namespace de WebSocket (ex: '/arena' ou '/lobby')
  static String wsNamespaceUrl(String namespace) {
    final cleanNs = namespace.startsWith('/') ? namespace : '/$namespace';
    return '$wsBaseUrl$cleanNs';
  }
}
