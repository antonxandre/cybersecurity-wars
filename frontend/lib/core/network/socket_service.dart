import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/auth/domain/services/auth_service.dart';
import '../config/api_config.dart';

enum SocketConnectionStatus {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// Serviço de infraestrutura para conexões em tempo real via Socket.IO com autenticação JWT.
class SocketService {
  final String namespace;
  io.Socket? _socket;
  SocketConnectionStatus _status = SocketConnectionStatus.disconnected;

  final StreamController<SocketConnectionStatus> _statusController =
      StreamController<SocketConnectionStatus>.broadcast();

  final Map<String, List<void Function(dynamic data)>> _registeredListeners = {};

  SocketService({this.namespace = '/arena'});

  SocketConnectionStatus get status => _status;
  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;
  bool get isConnected => _status == SocketConnectionStatus.connected;
  String? get socketId => _socket?.id;

  /// Estabelece a conexão WebSocket com o gateway NestJS.
  void connect() {
    if (_socket != null && _socket!.connected) return;
    if (_status == SocketConnectionStatus.connecting) return;

    _updateStatus(SocketConnectionStatus.connecting);
    final baseUrl = ApiConfig.wsBaseUrl;
    final token = AuthService.instance.accessToken;

    if (_socket != null) {
      if (token != null && token.isNotEmpty) {
        _socket?.io.options?['auth'] = {'token': token};
        _socket?.auth = {'token': token};
      }
      _attachRegisteredListeners();
      _socket?.connect();
      return;
    }

    try {
      final opts = io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath('/socket.io')
          .disableAutoConnect()
          .enableReconnection()
          .setReconnectionAttempts(10)
          .setReconnectionDelay(1000)
          .setReconnectionDelayMax(5000);

      if (token != null && token.isNotEmpty) {
        opts.setAuth({'token': token});
      }

      final uri = '$baseUrl$namespace';
      debugPrint('[SocketService] Conectando ao namespace: $uri');

      final socket = io.io(uri, opts.build());
      _socket = socket;

      // Anexa imediatamente listeners já registrados antes da conexão
      _attachRegisteredListeners();

      socket.onConnect((_) {
        debugPrint('[SocketService] Conectado ao namespace $namespace (ID: ${socket.id})');
        _updateStatus(SocketConnectionStatus.connected);
        _attachRegisteredListeners();
      });

      socket.onDisconnect((reason) {
        debugPrint('[SocketService] Desconectado de $namespace: $reason');
        _updateStatus(SocketConnectionStatus.disconnected);
      });

      socket.onConnectError((err) {
        debugPrint('[SocketService] Erro de conexão em $namespace: $err');
        _updateStatus(SocketConnectionStatus.error);
      });

      socket.on('reconnect', (_) {
        debugPrint('[SocketService] Reconectado com sucesso a $namespace');
        _updateStatus(SocketConnectionStatus.connected);
        _attachRegisteredListeners();
      });

      socket.on('reconnecting', (attempt) {
        debugPrint('[SocketService] Reconectando a $namespace (tentativa #$attempt)...');
        _updateStatus(SocketConnectionStatus.reconnecting);
      });

      socket.connect();
    } catch (e) {
      debugPrint('[SocketService] Exceção ao inicializar socket: $e');
      _updateStatus(SocketConnectionStatus.error);
    }
  }

  /// Registra um listener para eventos recebidos do servidor.
  void on(String event, void Function(dynamic data) handler) {
    _registeredListeners.putIfAbsent(event, () => []).add(handler);
    _socket?.on(event, handler);
  }

  /// Remove listener de evento.
  void off(String event, [void Function(dynamic data)? handler]) {
    if (handler != null) {
      _registeredListeners[event]?.remove(handler);
      _socket?.off(event, handler);
    } else {
      _registeredListeners.remove(event);
      _socket?.off(event);
    }
  }

  void _attachRegisteredListeners() {
    if (_socket == null) return;
    _registeredListeners.forEach((event, handlers) {
      for (final handler in handlers) {
        _socket!.off(event, handler);
        _socket!.on(event, handler);
      }
    });
  }

  /// Emite um evento para o servidor com payload opcional e callback de confirmação (Ack).
  void emit(String event, [dynamic data, Function? ack]) {
    if (_socket == null || !_socket!.connected) {
      debugPrint('[SocketService] Aviso: tentando emitir "$event" com socket desconectado.');
    }
    if (ack != null) {
      _socket?.emitWithAck(event, data, ack: ack);
    } else {
      _socket?.emit(event, data);
    }
  }

  /// Encerra a conexão WebSocket sem perder listeners registrados.
  void disconnect() {
    _socket?.disconnect();
    _updateStatus(SocketConnectionStatus.disconnected);
  }

  void _updateStatus(SocketConnectionStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
  }

  void dispose() {
    _registeredListeners.clear();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateStatus(SocketConnectionStatus.disconnected);
    _statusController.close();
  }
}
