import 'dart:async';
import 'dart:io';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';

/// Keeps the HTTP inspector's response buffering away from socket upgrades.
/// REST requests still use the global inspector; TLS and any pre-existing
/// HTTP client configuration are preserved for every socket reconnect.
class SupportWebSocketConnection implements PusherChannelsConnection {
  SupportWebSocketConnection({required this.uri, this.onDiagnostic});

  final Uri uri;
  final void Function(String message)? onDiagnostic;
  HttpClient? _httpClient;
  WebSocket? _socket;
  StreamSubscription<dynamic>? _subscription;
  bool _closed = false;

  static HttpOverrides? _beforeInspector;

  /// Call immediately before installing the app's global HTTP inspector.
  static void captureHttpOverridesBeforeInspector() {
    _beforeInspector = HttpOverrides.current ?? _DefaultSocketHttpOverrides();
  }

  @override
  void connect({
    required PusherChannelsConnectionOnDoneCallback onDoneCallback,
    required PusherChannelsConnectionOnErrorCallback onErrorCallback,
    required PusherChannelsConnectionOnEventCallback onEventCallback,
  }) async {
    try {
      _httpClient = _beforeInspector?.createHttpClient(null) ?? HttpClient();
      onDiagnostic?.call(
        'SOCKET ATTEMPT: opening ${uri.scheme}://${uri.host}:${uri.port}${uri.path}; '
        'inspector bypass=${_beforeInspector != null}',
      );
      final originScheme =
          uri.scheme == 'wss' || uri.scheme == 'https' ? 'https' : 'http';
      final origin = '$originScheme://${uri.host}';
      final socket = await WebSocket.connect(
        uri.toString(),
        customClient: _httpClient,
        headers: {
          'Origin': origin,
        },
      );
      if (_closed) {
        onDiagnostic?.call('SOCKET CANCELED: connected but connection was closed before listener attached');
        unawaited(socket.close());
        return;
      }
      _socket = socket;
      onDiagnostic?.call('SOCKET UPGRADE SUCCESS: Connected to ${uri.scheme}://${uri.host}:${uri.port}${uri.path}');
      _subscription = socket.listen(
        (event) {
          onDiagnostic?.call('SOCKET FRAME RECEIVED: $event');
          onEventCallback(event.toString());
        },
        onDone: () {
          if (_closed) return;
          onDiagnostic?.call(
            'SOCKET CLOSED: code=${socket.closeCode} '
            'reason=${_safeDetail(socket.closeReason ?? 'not supplied')}',
          );
          onDoneCallback();
        },
        onError: (Object error, StackTrace trace) {
          if (_closed) return;
          onDiagnostic?.call('SOCKET ERROR: ${_safeDetail(error)}');
          onErrorCallback(error, trace);
        },
        cancelOnError: true,
      );
    } catch (error, trace) {
      if (_closed) return;
      onDiagnostic?.call('SOCKET HANDSHAKE FAILED: ${_safeDetail(error)}');
      onErrorCallback(error, trace);
    }
  }

  String _safeDetail(Object value) => value.toString().replaceAll(
        uri.path,
        '/app/[redacted]',
      );

  @override
  void sendEvent(String eventEncoded) {
    onDiagnostic?.call('SOCKET SEND FRAME: $eventEncoded');
    if (!_closed) _socket?.add(eventEncoded);
  }

  @override
  void ping() {
    onDiagnostic?.call('SOCKET SEND PING: pusher:ping');
    sendEvent('{"event":"pusher:ping","data":{}}');
  }

  @override
  Future<void> close() async {
    if (_closed) return;
    onDiagnostic?.call('SOCKET CLOSING: terminating connection to ${uri.toString()}');
    _closed = true;
    await _subscription?.cancel();
    unawaited(_socket?.close());
    _httpClient?.close(force: true);
  }
}

class _DefaultSocketHttpOverrides extends HttpOverrides {}
