import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/api_config.dart';
import '../../../../core/storage/local_storage_adapter.dart';
import '../../../../core/utils/password_validator.dart';
import '../models/auth_user.dart';

/// Serviço de Autenticação com suporte a JWT, mitigação OWASP A01 & A07 e persistência de sessão.
class AuthService extends ChangeNotifier {
  static final AuthService instance = AuthService._internal();
  AuthService._internal();

  static const String _storageAccessKey = 'psa_jwt_access';
  static const String _storageRefreshKey = 'psa_jwt_refresh';

  AuthUser? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isSessionRestored = false;

  AuthUser? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get isAuthenticated => _currentUser != null;
  bool get isSessionRestored => _isSessionRestored;

  /// Sanitização de entrada para mitigar Injection (OWASP A03)
  String _sanitize(String input) {
    return input.trim().replaceAll(RegExp(r'[<>]'), '');
  }

  /// Inicializa e restaura a sessão JWT persistida ao recarregar o cliente Web.
  Future<bool> initializeSession() async {
    _isSessionRestored = true;
    final savedAccess = LocalStorageAdapter.getString(_storageAccessKey);
    final savedRefresh = LocalStorageAdapter.getString(_storageRefreshKey);

    if (savedAccess == null || savedAccess.isEmpty) {
      return false;
    }

    _accessToken = savedAccess;
    _refreshToken = savedRefresh;

    try {
      final meUri = ApiConfig.apiUrl('/auth/me');
      final response = await http.get(
        meUri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_accessToken',
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _currentUser = AuthUser.fromJson(data);
        notifyListeners();
        debugPrint('[AuthService] Sessão restaurada com sucesso para ${_currentUser?.username}');
        return true;
      } else if (response.statusCode == 401 && _refreshToken != null) {
        // Token de acesso expirou, tenta renovar via refresh token
        final refreshed = await refreshSession();
        return refreshed;
      } else {
        _clearPersistedTokens();
        return false;
      }
    } catch (e) {
      debugPrint('[AuthService] Falha ao verificar sessão remota ($e).');
      return false;
    }
  }

  /// Renova os tokens de acesso via refresh token (OWASP A07: rotação de sessão)
  Future<bool> refreshSession() async {
    if (_refreshToken == null || _refreshToken!.isEmpty) return false;

    try {
      final refreshUri = ApiConfig.apiUrl('/auth/refresh');
      final response = await http.post(
        refreshUri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'] ?? _refreshToken;

        if (_accessToken != null) {
          LocalStorageAdapter.setString(_storageAccessKey, _accessToken!);
        }
        if (_refreshToken != null) {
          LocalStorageAdapter.setString(_storageRefreshKey, _refreshToken!);
        }

        // Busca o perfil atualizado
        final meUri = ApiConfig.apiUrl('/auth/me');
        final meRes = await http.get(
          meUri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_accessToken',
          },
        ).timeout(const Duration(seconds: 4));

        if (meRes.statusCode == 200) {
          _currentUser = AuthUser.fromJson(jsonDecode(meRes.body));
          notifyListeners();
          return true;
        }
      }
    } catch (e) {
      debugPrint('[AuthService] Falha ao renovar refresh token: $e');
    }

    _clearPersistedTokens();
    return false;
  }

  /// Realiza login no backend NestJS via API REST
  Future<({bool success, String? errorMessage})> login({
    required String email,
    required String password,
    UserRole fallbackRole = UserRole.blueTeam,
  }) async {
    final cleanEmail = _sanitize(email);
    final cleanPassword = password.trim();

    if (cleanEmail.isEmpty) {
      return (success: false, errorMessage: 'O email é obrigatório.');
    }

    final loginValidation = PasswordValidator.validateLogin(cleanPassword);
    if (!loginValidation.isValid) {
      return (success: false, errorMessage: loginValidation.errorMessage);
    }

    try {
      final loginUri = ApiConfig.apiUrl('/auth/login');
      final response = await http
          .post(
            loginUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'password': cleanPassword}),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _currentUser = AuthUser.fromJson(data['user'] ?? {});

        if (_accessToken != null) {
          LocalStorageAdapter.setString(_storageAccessKey, _accessToken!);
        }
        if (_refreshToken != null) {
          LocalStorageAdapter.setString(_storageRefreshKey, _refreshToken!);
        }

        notifyListeners();
        return (success: true, errorMessage: null);
      } else {
        // OWASP A07: Mensagem genérica para mitigar User Enumeration
        return (
          success: false,
          errorMessage: 'Credenciais inválidas ou acesso temporariamente bloqueado.',
        );
      }
    } catch (e) {
      debugPrint('[AuthService] Erro de rede na autenticação: $e');
      return (
        success: false,
        errorMessage: 'Não foi possível conectar ao servidor de autenticação. Verifique sua conexão e tente novamente.',
      );
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

    if (cleanEmail.isEmpty || cleanUsername.isEmpty) {
      return (
        success: false,
        errorMessage: 'Preencha todos os campos obrigatórios (email e nome).',
      );
    }

    final strength = PasswordValidator.analyze(password);
    if (!strength.isValid) {
      return (
        success: false,
        errorMessage: strength.errorMessage ??
            'A senha deve possuir pelo menos 8 caracteres, incluindo letras maiúsculas, minúsculas, números e caracteres especiais.',
      );
    }

    try {
      final regUri = ApiConfig.apiUrl('/auth/register');
      final response = await http
          .post(
            regUri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': cleanEmail,
              'username': cleanUsername,
              'password': password,
              'role': role == UserRole.redTeam ? 'RED_TEAM' : 'BLUE_TEAM',
            }),
          )
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _accessToken = data['accessToken'];
        _refreshToken = data['refreshToken'];
        _currentUser = AuthUser.fromJson(data['user'] ?? {});

        if (_accessToken != null) {
          LocalStorageAdapter.setString(_storageAccessKey, _accessToken!);
        }
        if (_refreshToken != null) {
          LocalStorageAdapter.setString(_storageRefreshKey, _refreshToken!);
        }

        notifyListeners();
        return (success: true, errorMessage: null);
      } else {
        String msg = 'Falha ao registrar operador. Verifique os dados informados.';
        try {
          final errData = jsonDecode(response.body);
          if (errData['message'] is String) {
            msg = errData['message'];
          } else if (errData['message'] is List && errData['message'].isNotEmpty) {
            msg = errData['message'].first.toString();
          }
        } catch (_) {}
        return (success: false, errorMessage: msg);
      }
    } catch (e) {
      debugPrint('[AuthService] Erro de rede no cadastro: $e');
      return (
        success: false,
        errorMessage: 'Servidor indisponível no momento. Tente novamente mais tarde.',
      );
    }
  }

  /// Ativação instantânea de operador demo para modo de desenvolvimento
  void loginDemo(UserRole role) {
    if (!kDebugMode) {
      debugPrint('[AuthService] loginDemo bloqueado em ambiente de produção.');
      return;
    }
    _currentUser = AuthUser(
      id: 'demo_${role.name}',
      email: '${role.name}@promptsec.arena',
      username: role == UserRole.blueTeam ? 'Operador Blue (Dev)' : 'Operador Red (Dev)',
      role: role,
    );
    _accessToken = 'demo_session_token';
    notifyListeners();
  }

  void _clearPersistedTokens() {
    LocalStorageAdapter.remove(_storageAccessKey);
    LocalStorageAdapter.remove(_storageRefreshKey);
    _currentUser = null;
    _accessToken = null;
    _refreshToken = null;
    notifyListeners();
  }

  /// Encerra a sessão e destrói tokens em memória e armazenamento (OWASP A01 & A07)
  Future<void> logout() async {
    try {
      if (_accessToken != null) {
        final logoutUri = ApiConfig.apiUrl('/auth/logout');
        await http
            .post(
              logoutUri,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_accessToken',
              },
            )
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {
      // Ignora erro de rede no logout para garantir destruição local
    } finally {
      _clearPersistedTokens();
      debugPrint('[AuthService] Sessão destruída com sucesso. Redirecionando para login.');
    }
  }
}
