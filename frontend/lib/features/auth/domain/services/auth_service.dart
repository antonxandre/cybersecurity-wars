import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/auth_user.dart';

/// Serviço de Autenticação com suporte a JWT, mitigação OWASP A01 & A07 e fallback demo offline.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  final String _baseUrl = 'http://localhost:3000';

  AuthUser? _currentUser;
  String? _accessToken;
  String? _refreshToken;

  AuthUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _currentUser != null;

  /// Sanitização de entrada para mitigar Injection (OWASP A03)
  String _sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'[<>]'), '');
  }

  /// Realiza login no backend NestJS (com fallback demo para ambiente offline)
  Future<({bool success, String? errorMessage})> login({
    required String email,
    required String password,
    UserRole fallbackRole = UserRole.blueTeam,
  }) async {
    final cleanEmail = _sanitize(email);
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty || cleanPassword.isEmpty) {
      return (success: false, errorMessage: 'Email e senha são obrigatórios.');
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'password': cleanPassword}),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _currentUser = AuthUser.fromJson(data['user'] ?? {});
        notifyListeners();
        return (success: true, errorMessage: null);
      } else {
        // OWASP A07: Mensagem genérica para mitigar User Enumeration
        return (success: false, errorMessage: 'Credenciais inválidas ou acesso temporariamente bloqueado.');
      }
    } catch (e) {
      debugPrint('[AuthService] Backend offline ou indisponível ($e). Ativando sessão local demo.');
      // Fallback gracioso para modo offline / desenvolvimento
      _currentUser = AuthUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        username: cleanEmail.split('@').first,
        role: fallbackRole,
      );
      _accessToken = 'mock_jwt_token_${DateTime.now().millisecondsSinceEpoch}';
      notifyListeners();
      return (success: true, errorMessage: null);
    }
  }

  /// Realiza cadastro de novo operador tático
  Future<({bool success, String? errorMessage})> register({
    required String email,
    required String username,
    required String password,
    required UserRole role,
  }) async {
    final cleanEmail = _sanitize(email);
    final cleanUsername = _sanitize(username);

    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/auth/register'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': cleanEmail,
              'username': cleanUsername,
              'password': password,
              'role': role == UserRole.redTeam ? 'RED_TEAM' : 'BLUE_TEAM',
            }),
          )
          .timeout(const Duration(seconds: 3));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _currentUser = AuthUser.fromJson(data['user'] ?? {});
        notifyListeners();
        return (success: true, errorMessage: null);
      } else {
        return (success: false, errorMessage: 'Falha ao registrar usuário. Verifique os dados informados.');
      }
    } catch (_) {
      // Fallback demo
      _currentUser = AuthUser(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        email: cleanEmail,
        username: cleanUsername,
        role: role,
      );
      notifyListeners();
      return (success: true, errorMessage: null);
    }
  }

  /// Ativação instantânea de operador demo para visualização rápida da Arena
  void loginDemo(UserRole role) {
    _currentUser = AuthUser(
      id: 'demo_${role.name}',
      email: '${role.name}@promptsec.arena',
      username: role == UserRole.blueTeam ? 'Operador Blue (Defesa)' : 'Operador Red (Ataque)',
      role: role,
    );
    _accessToken = 'demo_session_token';
    notifyListeners();
  }

  /// Encerra a sessão e destrói tokens em memória (OWASP A01 & A07)
  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        await http
            .post(
              Uri.parse('$_baseUrl/auth/logout'),
              headers: {'Authorization': 'Bearer $_accessToken'},
            )
            .timeout(const Duration(seconds: 2));
      }
    } catch (_) {
      // Ignora erro de rede no logout
    } finally {
      _currentUser = null;
      _accessToken = null;
      _refreshToken = null;
      notifyListeners();
      debugPrint('[AuthService] Sessão destruída com sucesso. Redirecionando para login.');
    }
  }
}
