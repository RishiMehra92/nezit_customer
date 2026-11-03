import 'dart:async';

import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter/foundation.dart';

import '../model/support_models.dart';
import 'support_websocket_connection.dart';

class SupportRealtimeEvent {
  const SupportRealtimeEvent(this.name, this.data);

  final String name;
  final Map<String, dynamic> data;
}

class SupportRealtimeService {
  final _events = StreamController<SupportRealtimeEvent>.broadcast();
  final _live = StreamController<bool>.broadcast();

  PusherChannelsClient? _client;
  PrivateChannel? _threadChannel;
  PresenceChannel? _presenceChannel;
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  bool _isLive = false;
  PusherChannelsClientLifeCycleState _lifecycleState =
      PusherChannelsClientLifeCycleState.inactive;
  bool _retrying = false;
  bool _clientWhispersEnabled = true;

  Stream<SupportRealtimeEvent> get events => _events.stream;
  Stream<bool> get liveChanges => _live.stream;
  bool get isLive => _isLive;

  Future<void> connect({
    required SupportRealtimeConfig config,
    required String threadUuid,
    Map<String, String>? headers,
  }) async {
    await disconnect();
    if (!config.isConfigured || threadUuid.isEmpty) {
      _debug(
        '⚠️ CANNOT CONNECT WEBSOCKET: '
        'config.isConfigured=${config.isConfigured}, threadUuid="$threadUuid"',
      );
      _setLive(false);
      return;
    }

    try {
      final authUri = Uri.tryParse(config.authEndpoint);
      if (authUri == null || !authUri.hasScheme) {
        _debug('❌ INVALID AUTH ENDPOINT: "${config.authEndpoint}"');
        _setLive(false);
        return;
      }

      final scheme = config.scheme == 'http' ? 'ws' : 'wss';
      final key = config.key!;
      final PusherChannelsOptions options = config.driver == 'pusher'
          ? PusherChannelsOptions.fromCluster(
              scheme: scheme,
              cluster: config.cluster,
              key: key,
              port: config.port,
            )
          : PusherChannelsOptions.fromHost(
              scheme: scheme,
              host: config.host!,
              key: key,
              port: config.port,
            );

      _debug('--------------------------------------------------');
      _debug('🔌 STARTING WEBSOCKET CONNECTION FLOW:');
      _debug('  - Driver:      "${config.driver}"');
      _debug('  - Scheme:      "$scheme"');
      _debug('  - Key:         "$key"');
      _debug('  - Target Host: "${config.driver == 'pusher' ? config.cluster : config.host}"');
      _debug('  - Port:        ${config.port}');
      _debug('  - Full WS URI: "${options.uri}"');
      _debug('  - Thread UUID: "$threadUuid"');
      _debug('--------------------------------------------------');

      final client = PusherChannelsClient.custom(
        connectionDelegate: () => SupportWebSocketConnection(
          uri: options.uri,
          onDiagnostic: _debug,
        ),
        minimumReconnectDelayDuration: const Duration(seconds: 2),
        connectionErrorHandler: (error, trace, refresh) {
          _debug('❌ TRANSPORT ERROR: $error');
          _setLive(false);
          refresh();
        },
      );
      _client = client;
      _clientWhispersEnabled = true;

      final authHeaders = Map<String, String>.from(headers ?? const {});
      if (authHeaders.isEmpty) {
        _debug('⚠️ WARNING: Auth headers map is empty when authorizing channels at ${config.authEndpoint}!');
      }
      authHeaders.removeWhere((name, _) {
        final lower = name.toLowerCase();
        return lower == 'content-type' ||
            lower == 'content-length' ||
            lower == 'host';
      });
      final safeAuthHeaders = authHeaders.map((k, v) => MapEntry(k, k == 'Authorization' ? '${v.substring(0, v.length > 20 ? 20 : v.length)}...' : v));
      _debug('🔒 AUTHORIZING PRIVATE & PRESENCE CHANNELS:');
      _debug('  - Auth Endpoint: "$authUri"');
      _debug('  - Auth Headers:  $safeAuthHeaders');

      final privateChannel = client.privateChannel(
        'private-support.thread.$threadUuid',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPrivateChannel(
          authorizationEndpoint: authUri,
          headers: authHeaders,
          onAuthFailed: (error, trace) {
            _debug('❌ PRIVATE CHANNEL AUTH FAILED: $error (Endpoint: $authUri, Headers: $safeAuthHeaders)');
            _setLive(false);
          },
        ),
      );
      final presenceChannel = client.presenceChannel(
        'presence-support.presence.thread.$threadUuid',
        authorizationDelegate:
            EndpointAuthorizableChannelTokenAuthorizationDelegate
                .forPresenceChannel(
          authorizationEndpoint: authUri,
          headers: authHeaders,
          onAuthFailed: (error, trace) {
            _debug('❌ PRESENCE CHANNEL AUTH FAILED: $error (Endpoint: $authUri, Headers: $safeAuthHeaders)');
            _setLive(false);
          },
        ),
      );
      _threadChannel = privateChannel;
      _presenceChannel = presenceChannel;

      _subscriptions.addAll([
        privateChannel.whenSubscriptionSucceeded().listen((_) {
          _debug('✅ PRIVATE CHANNEL SUBSCRIPTION SUCCEEDED! (private-support.thread.$threadUuid)');
          _setLive(true);
        }),
        privateChannel.onSubscriptionError().listen((event) {
          _debug(
            '❌ PRIVATE CHANNEL SUBSCRIPTION FAILED: '
            '${event.tryGetDataAsMap()?['type'] ?? 'unknown'} (Raw: ${event.data})',
          );
          _setLive(false);
        }),
        presenceChannel.whenSubscriptionSucceeded().listen((_) {
          _debug('✅ PRESENCE CHANNEL SUBSCRIPTION SUCCEEDED! (presence-support.presence.thread.$threadUuid)');
        }),
        presenceChannel.onSubscriptionError().listen((event) {
          _debug(
            '❌ PRESENCE CHANNEL SUBSCRIPTION FAILED: '
            '${event.tryGetDataAsMap()?['type'] ?? 'unknown'} (Raw: ${event.data})',
          );
        }),
        privateChannel.bind('support.activity').listen((event) {
          final data = event.tryGetDataAsMap();
          _debug('📩 REALTIME EVENT RECEIVED [support.activity]: $data');
          _emit('support.activity', data);
        }),
        privateChannel.bind('support.typing').listen((event) {
          final data = event.tryGetDataAsMap();
          _debug('📩 REALTIME EVENT RECEIVED [support.typing]: $data');
          _emit('support.typing', data);
        }),
        presenceChannel.bind('client-typing').listen((event) {
          final data = event.tryGetDataAsMap();
          _debug('📩 REALTIME EVENT RECEIVED [client-typing]: $data');
          _emit('support.typing', data);
        }),
        client.pusherErrorEventStream.listen((event) {
          final data = event.tryGetDataAsMap();
          final message = data?['message']?.toString() ?? '';
          final code = data?['code']?.toString() ?? '';
          _debug('⚠️ PUSHER PROTOCOL ERROR [code=$code]: ${message.isEmpty ? event.data : message}');
          if (message.toLowerCase().contains('client events')) {
            _clientWhispersEnabled = false;
            _debug('⚠️ Client typing whisper disabled due to server settings; REST typing remains active');
          }
        }),
        client.lifecycleStream.listen((state) {
          _lifecycleState = state;
          _debug('🔄 LIFECYCLE STATE CHANGED: ${state.name}');
          if (_transportIsUnavailable(state)) {
            _setLive(false);
          }
        }),
        client.onConnectionEstablished.listen((_) {
          _debug('⚡ TRANSPORT ESTABLISHED: Subscribing to private & presence channels...');
          privateChannel.subscribeIfNotUnsubscribed();
          presenceChannel.subscribeIfNotUnsubscribed();
        }),
      ]);

      unawaited(client.connect());
    } catch (e) {
      _debug('❌ CONNECT EXCEPTION: $e');
      _setLive(false);
    }
  }

  Future<void> retry() async {
    final client = _client;
    if (client == null || _isLive || _retrying) return;
    _retrying = true;
    _debug('🔄 RETRYING WEBSOCKET / CHANNEL AUTHORIZATION (State: ${_lifecycleState.name}, isLive: $_isLive)');
    try {
      if (_lifecycleState ==
          PusherChannelsClientLifeCycleState.establishedConnection) {
        _threadChannel?.subscribeIfNotUnsubscribed();
        _presenceChannel?.subscribeIfNotUnsubscribed();
      } else if (_lifecycleState !=
              PusherChannelsClientLifeCycleState.pendingConnection &&
          _lifecycleState != PusherChannelsClientLifeCycleState.reconnecting) {
        await client.reconnect();
      }
    } catch (e) {
      _debug('❌ RETRY EXCEPTION: $e');
      _setLive(false);
    } finally {
      _retrying = false;
    }
  }

  void whisperTyping(bool typing) {
    if (!_isLive || !_clientWhispersEnabled) {
      _debug('⚠️ WHISPER TYPING SKIPPED (isLive: $_isLive, clientWhispersEnabled: $_clientWhispersEnabled)');
      return;
    }
    _debug('💬 WHISPERING CLIENT TYPING: typing=$typing');
    _presenceChannel?.trigger(
      eventName: 'client-typing',
      data: {'role': 'customer', 'typing': typing},
    );
  }

  Future<void> disconnect() async {
    _debug('🔌 DISCONNECTING WEBSOCKET SERVICE...');
    _setLive(false);
    _lifecycleState = PusherChannelsClientLifeCycleState.inactive;
    _retrying = false;
    _clientWhispersEnabled = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
    _threadChannel?.unsubscribe();
    _presenceChannel?.unsubscribe();
    _threadChannel = null;
    _presenceChannel = null;
    _client?.dispose();
    _client = null;
  }

  void _emit(String name, Map<String, dynamic>? data) {
    if (data != null && !_events.isClosed) {
      _events.add(SupportRealtimeEvent(name, data));
    }
  }

  void _setLive(bool value) {
    if (_isLive == value) return;
    _isLive = value;
    _debug('private channel live: $value');
    if (!_live.isClosed) _live.add(value);
  }


  static bool _transportIsUnavailable(
    PusherChannelsClientLifeCycleState state,
  ) =>
      switch (state) {
        PusherChannelsClientLifeCycleState.establishedConnection ||
        PusherChannelsClientLifeCycleState.gotPusherError =>
          false,
        _ => true,
      };

  void _debug(String message) {
    if (kDebugMode) debugPrint('[SupportRealtime] $message');
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
    await _live.close();
  }
}
