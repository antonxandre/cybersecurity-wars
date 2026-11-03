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

  SocketService({this.namespace = '/arena'});

  SocketConnectionStatus get status => _status;
  Stream<SocketConnectionStatus> get statusStream => _statusController.stream;
  bool get isConnected => _status == SocketConnectionStatus.connected;
  String? get socketId => _socket?.id;

  /// Estabelece a conexão WebSocket com o gateway NestJS.
  void connect() {
    if (_socket != null && _socket!.connected) return;

    _updateStatus(SocketConnectionStatus.connecting);
    final baseUrl = ApiConfig.wsBaseUrl;
    final token = AuthService.instance.accessToken;

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

      _socket = io.io(uri, opts.build());

      _socket?.onConnect((_) {
        debugPrint('[SocketService] Conectado ao namespace $namespace (ID: ${_socket?.id})');
        _updateStatus(SocketConnectionStatus.connected);
      });

      _socket?.onDisconnect((reason) {
        debugPrint('[SocketService] Desconectado de $namespace: $reason');
        _updateStatus(SocketConnectionStatus.disconnected);
      });

      _socket?.onConnectError((err) {
        debugPrint('[SocketService] Erro de conexão em $namespace: $err');
        _updateStatus(SocketConnectionStatus.error);
      });

      _socket?.on('reconnecting', (attempt) {
        debugPrint('[SocketService] Reconectando a $namespace (tentativa #$attempt)...');
        _updateStatus(SocketConnectionStatus.reconnecting);
      });

      _socket?.connect();
    } catch (e) {
      debugPrint('[SocketService] Exceção ao inicializar socket: $e');
      _updateStatus(SocketConnectionStatus.error);
    }
  }

  /// Registra um listener para eventos recebidos do servidor.
  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  /// Remove listener de evento.
  void off(String event) {
    _socket?.off(event);
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

  /// Encerra a conexão WebSocket.
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _updateStatus(SocketConnectionStatus.disconnected);
  }

  void _updateStatus(SocketConnectionStatus newStatus) {
    _status = newStatus;
    if (!_statusController.isClosed) {
      _statusController.add(_status);
    }
  }

  void dispose() {
    disconnect();
    _statusController.close();
  }
}
