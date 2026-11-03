import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../config/security.dart';
import '../model/support_models.dart';
import '../repo/support_repository.dart';
import '../service/support_realtime_service.dart';
import '../service/support_attachment_cache.dart';

part 'support_event.dart';
part 'support_state.dart';

class SupportBloc extends Bloc<SupportEvent, SupportState> {
  SupportBloc({
    required SupportRepository repository,
    required SupportRealtimeService realtime,
  })  : _repository = repository,
        _realtime = realtime,
        super(const SupportState()) {
    on<SupportStarted>(_onStarted);
    on<SupportRefreshRequested>(_onRefresh);
    on<SupportLoadOlderRequested>(_onLoadOlder);
    on<SupportFlowOpened>((_, emit) => emit(state.copyWith(
          flowOpen: true,
          orderSelectionMade: false,
          selectedOrderId: null,
          selectedTopicId: null,
          error: null,
        )));
    on<SupportFlowClosed>((_, emit) => emit(state.copyWith(flowOpen: false)));
    on<SupportFlowBackRequested>((_, emit) {
      if (state.hasActiveSession || state.sending) return;
      emit(state.selectedTopicId != null
          ? state.copyWith(selectedTopicId: null, error: null)
          : state.copyWith(
              orderSelectionMade: false,
              selectedOrderId: null,
              error: null,
            ));
    });
    on<SupportOrderSelected>(_onOrderSelected);
    on<SupportTopicSelected>(_onTopicSelected);
    on<SupportDraftChanged>(_onDraftChanged);
    on<SupportAttachmentsSelected>(_onAttachmentsSelected);
    on<SupportAttachmentRemoved>(_onAttachmentRemoved);
    on<SupportStartSessionRequested>(_onStartSession);
    on<SupportSendRequested>(_onSend);
    on<SupportRetryMessageRequested>(_onRetry);
    on<SupportCallbackRequested>(_onCallback);
    on<SupportResolveRequested>(_onResolve);
    on<SupportRatingScoreChanged>(
      (event, emit) => emit(state.copyWith(ratingScore: event.score)),
    );
    on<SupportRatingFeedbackChanged>(
      (event, emit) => emit(state.copyWith(ratingFeedback: event.feedback)),
    );
    on<SupportRatingSubmitted>(_onSubmitRating);
    on<SupportConnectivityChanged>(_onConnectivityChanged);
    on<SupportAppResumed>(_onAppResumed);
    on<SupportAppPaused>(_onAppPaused);
    on<SupportFeedbackConsumed>(
      (_, emit) => emit(state.copyWith(notice: null, error: null)),
    );
    on<_SupportRealtimeChanged>(_onRealtimeChanged);
    on<_SupportRealtimeReceived>(_onRealtimeReceived);
    on<_SupportPollRequested>(_onPoll);
    on<_SupportTypingStopped>(_onTypingStopped);
    on<_SupportRemoteTypingExpired>(
      (_, emit) => emit(state.copyWith(remoteTyping: false)),
    );

    _liveSubscription = _realtime.liveChanges.listen(
      (live) => add(_SupportRealtimeChanged(live)),
    );
    _eventSubscription = _realtime.events.listen(
      (event) => add(_SupportRealtimeReceived(event)),
    );
  }

  final SupportRepository _repository;
  final SupportRealtimeService _realtime;
  static const _uuid = Uuid();
  late final StreamSubscription<bool> _liveSubscription;
  late final StreamSubscription<SupportRealtimeEvent> _eventSubscription;
  Timer? _pollTimer;
  Timer? _typingTimer;
  Timer? _remoteTypingTimer;
  bool _polling = false;
  final _temporaryAttachments = <SupportLocalAttachment>[];
  bool _closing = false;
  bool _fullRefreshRequested = false;
  bool _typingSent = false;
  String? _configuredThreadUuid;
  String? _configuredRealtimeFingerprint;

  Future<void> _onStarted(
    SupportStarted event,
    Emitter<SupportState> emit,
  ) async {
    emit(state.copyWith(status: SupportLoadStatus.loading, error: null));
    try {
      final payload = await _repository.getThread();
      final topics = await _repository.getTopics();
      final messages = payload.thread.messages;
      final initialOrderExists = event.initialOrderId != null &&
          payload.recentOrders.any((order) => order.id == event.initialOrderId);
      emit(state.copyWith(
        status: SupportLoadStatus.loaded,
        payload: payload,
        topics: topics,
        messages: messages,
        flowOpen: payload.thread.sessions.isEmpty || initialOrderExists,
        orderSelectionMade: initialOrderExists,
        selectedOrderId: initialOrderExists ? event.initialOrderId : null,
        messageCursor: _lastMessageId(messages),
        callCursor: _lastCallId(payload.thread.sessions),
        hasMoreMessages: payload.thread.hasMoreMessages,
        oldestMessageId: payload.thread.oldestMessageId,
        connectionMode: _mode(payload, live: false),
      ));
      await _connect(payload);
      _configurePolling();
      await _markLatestRead();
    } catch (error) {
      emit(state.copyWith(
        status: SupportLoadStatus.failed,
        error: error.toString(),
        connectionMode: SupportConnectionMode.offline,
      ));
    }
  }

  Future<void> _onRefresh(
    SupportRefreshRequested event,
    Emitter<SupportState> emit,
  ) =>
      _refreshThread(emit,
          showLoading: state.payload == null, resetMessages: true);

  Future<void> _refreshThread(
    Emitter<SupportState> emit, {
    bool showLoading = false,
    bool resetMessages = false,
  }) async {
    if (showLoading) emit(state.copyWith(status: SupportLoadStatus.loading));
    final messagesAtStart = state.messages.map((message) => message.id).toSet();
    try {
      final payload = await _repository.getThread();
      var serverMessages = payload.thread.messages;
      var hasMore = payload.thread.hasMoreMessages;
      var oldestId = payload.thread.oldestMessageId;
      final loadedIds = state.messages.where((message) => message.id > 0);
      final loadedBoundary = loadedIds.isEmpty
          ? null
          : loadedIds
              .map((message) => message.id)
              .reduce((a, b) => a < b ? a : b);
      while (resetMessages &&
          hasMore &&
          oldestId != null &&
          loadedBoundary != null &&
          oldestId > loadedBoundary) {
        final page = await _repository.getOlderMessages(oldestId);
        serverMessages = _mergeMessages(page.messages, serverMessages);
        hasMore = page.hasMore;
        final nextId = page.oldestMessageId;
        if (nextId == null || nextId >= oldestId) break;
        oldestId = nextId;
      }
      final pending =
          state.messages.where((message) => message.id <= 0).toList();
      final receivedDuringRefresh = state.messages
          .where((message) =>
              message.id > 0 && !messagesAtStart.contains(message.id))
          .toList();
      final messages = resetMessages
          ? _mergeMessages(
              serverMessages, [...receivedDuringRefresh, ...pending])
          : _mergeMessages(state.messages, serverMessages);
      if (_closing || emit.isDone) return;
      emit(state.copyWith(
        status: SupportLoadStatus.loaded,
        payload: payload,
        messages: messages,
        messageCursor: _lastMessageId(messages) > state.messageCursor
            ? _lastMessageId(messages)
            : state.messageCursor,
        callCursor: _lastCallId(payload.thread.sessions),
        hasMoreMessages: resetMessages ? hasMore : state.hasMoreMessages,
        oldestMessageId: resetMessages ? oldestId : state.oldestMessageId,
        connectionMode: _mode(payload, live: _realtime.isLive),
        error: null,
      ));
      await _connect(payload);
      _configurePolling();
      await _markLatestRead();
    } catch (error) {
      if (_closing || emit.isDone) return;
      emit(state.copyWith(
        status: state.payload == null ? SupportLoadStatus.failed : state.status,
        error: error.toString(),
        connectionMode: state.connected && _realtime.isLive
            ? state.connectionMode
            : SupportConnectionMode.offline,
      ));
    }
  }

  Future<void> _connect(SupportThreadPayload payload) async {
    final config = payload.realtime;
    final fingerprint = [
      config.driver,
      config.key,
      config.host,
      config.port,
      config.scheme,
      config.cluster,
      config.authEndpoint,
    ].join('|');
    if (_configuredThreadUuid == payload.thread.uuid &&
        _configuredRealtimeFingerprint == fingerprint) {
      if (kDebugMode) {
        debugPrint('[SupportBloc] Realtime connection config unchanged for Thread UUID "${payload.thread.uuid}". Skipping reconnect.');
      }
      return;
    }
    _configuredThreadUuid = payload.thread.uuid;
    _configuredRealtimeFingerprint = fingerprint;
    if (kDebugMode) {
      debugPrint('[SupportBloc] ----------------------------------------');
      debugPrint('[SupportBloc] INITIATING REALTIME CONNECTION FROM BLOC:');
      debugPrint('[SupportBloc]   - Thread UUID:    "${payload.thread.uuid}"');
      debugPrint('[SupportBloc]   - Driver:         "${config.driver}"');
      debugPrint('[SupportBloc]   - Key:            "${config.key}"');
      debugPrint('[SupportBloc]   - Target Host:    "${config.host}"');
      debugPrint('[SupportBloc]   - Target Cluster: "${config.cluster}"');
      debugPrint('[SupportBloc]   - Auth Endpoint:  "${config.authEndpoint}"');
      debugPrint('[SupportBloc]   - isConfigured:   ${config.isConfigured}');
      debugPrint('[SupportBloc] ----------------------------------------');
    }
    try {
      await _realtime.connect(
        config: config,
        threadUuid: payload.thread.uuid,
        headers: headers,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[SupportBloc] ❌ Realtime connect exception: $e');
      }
    }
  }

  Future<void> _onLoadOlder(
    SupportLoadOlderRequested event,
    Emitter<SupportState> emit,
  ) async {
    final before = state.oldestMessageId;
    if (before == null || state.loadingOlder || !state.hasMoreMessages) return;
    emit(state.copyWith(loadingOlder: true, error: null));
    try {
      final page = await _repository.getOlderMessages(before);
      emit(state.copyWith(
        loadingOlder: false,
        messages: _mergeMessages(page.messages, state.messages),
        hasMoreMessages: page.hasMore,
        oldestMessageId: page.oldestMessageId,
      ));
    } catch (error) {
      emit(state.copyWith(loadingOlder: false, error: error.toString()));
    }
  }

  void _onOrderSelected(
    SupportOrderSelected event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(
      orderSelectionMade: true,
      selectedOrderId: event.orderId,
      selectedTopicId: null,
      error: null,
    ));
  }

  void _onTopicSelected(
    SupportTopicSelected event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(selectedTopicId: event.topicId, error: null));
  }

  void _onDraftChanged(
    SupportDraftChanged event,
    Emitter<SupportState> emit,
  ) {
    final value = event.value.length > 4000
        ? event.value.substring(0, 4000)
        : event.value;
    emit(state.copyWith(draft: value, error: null));
    if (state.activeSession == null) return;
    if (value.trim().isNotEmpty) {
      debugPrint('[SupportBloc] Draft changed ("$value") -> Sending typing indicator...');
      _sendTyping(true);
      _typingTimer?.cancel();
      _typingTimer = Timer(
        const Duration(milliseconds: 1800),
        () => add(const _SupportTypingStopped()),
      );
    } else {
      debugPrint('[SupportBloc] Draft cleared -> Stopping typing indicator');
      add(const _SupportTypingStopped());
    }
  }

  void _onAttachmentsSelected(
    SupportAttachmentsSelected event,
    Emitter<SupportState> emit,
  ) {
    final merged = <SupportLocalAttachment>[...state.attachments];
    for (final file in event.attachments) {
      if (file.temporary) _temporaryAttachments.add(file);
      if (merged.length >= 5 ||
          file.size > 10 * 1024 * 1024 ||
          !const ['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
              .contains(file.mimeType)) {
        continue;
      }
      if (!merged.any((existing) => existing.path == file.path)) {
        merged.add(file);
      }
    }
    emit(state.copyWith(attachments: merged, error: null));
  }

  void _onAttachmentRemoved(
    SupportAttachmentRemoved event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(
      attachments:
          state.attachments.where((file) => file.path != event.path).toList(),
    ));
  }

  Future<void> _onStartSession(
    SupportStartSessionRequested event,
    Emitter<SupportState> emit,
  ) async {
    if (!state.canStartSession || state.hasActiveSession) return;
    emit(state.copyWith(sending: true, error: null, notice: null));
    try {
      await _repository.startSession(
        topicId: state.selectedTopicId!,
        orderId: state.selectedOrderId,
        message: state.draft,
        attachments: state.attachments,
      );
      emit(state.copyWith(
        sending: false,
        draft: '',
        attachments: const [],
        flowOpen: false,
        selectedTopicId: null,
        notice: 'Support conversation started.',
      ));
      await _refreshThread(emit, resetMessages: true);
    } on SupportApiException catch (error) {
      emit(state.copyWith(sending: false, error: error.message));
      if (error.isConflict) await _refreshThread(emit, resetMessages: true);
    } catch (error) {
      emit(state.copyWith(sending: false, error: error.toString()));
    }
  }

  Future<void> _onSend(
    SupportSendRequested event,
    Emitter<SupportState> emit,
  ) async {
    final session = state.activeSession;
    final text = state.draft.trim();
    final files = List<SupportLocalAttachment>.from(state.attachments);
    if (session == null || state.sending || (text.isEmpty && files.isEmpty)) {
      return;
    }

    final clientId = _uuid.v4();
    final optimistic = SupportMessage(
      id: -DateTime.now().microsecondsSinceEpoch,
      sessionId: session.id,
      clientMessageId: clientId,
      senderRole: 'user',
      senderName: state.thread?.customer.name,
      type: 'text',
      text: text,
      attachments: const [],
      createdAt: DateTime.now(),
      pending: true,
      localFiles: files,
    );
    emit(state.copyWith(
      sending: true,
      draft: '',
      attachments: const [],
      messages: [...state.messages, optimistic],
      error: null,
    ));
    await _stopTyping();
    try {
      final sent = await _repository.sendMessage(
        slug: session.slug,
        message: text,
        attachments: files,
        clientMessageId: clientId,
      );
      emit(state.copyWith(
        sending: false,
        messages: _replaceOptimistic(state.messages, clientId, sent),
        messageCursor:
            sent.id > state.messageCursor ? sent.id : state.messageCursor,
      ));
      await _markLatestRead();
    } catch (error) {
      emit(state.copyWith(
        sending: false,
        messages: state.messages
            .map((message) => message.clientMessageId == clientId
                ? message.copyWith(pending: false, failed: true)
                : message)
            .toList(),
        error: error.toString(),
      ));
    }
  }

  Future<void> _onRetry(
    SupportRetryMessageRequested event,
    Emitter<SupportState> emit,
  ) async {
    final session = state.activeSession;
    if (session == null || state.sending) return;
    SupportMessage? failed;
    for (final message in state.messages) {
      if (message.clientMessageId == event.clientMessageId && message.failed) {
        failed = message;
        break;
      }
    }
    if (failed == null) return;
    emit(state.copyWith(
      sending: true,
      messages: state.messages
          .map((message) => message.clientMessageId == event.clientMessageId
              ? message.copyWith(pending: true, failed: false)
              : message)
          .toList(),
      error: null,
    ));
    try {
      final sent = await _repository.sendMessage(
        slug: session.slug,
        message: failed.text,
        attachments: failed.localFiles,
        clientMessageId: event.clientMessageId,
      );
      emit(state.copyWith(
        sending: false,
        messages: _replaceOptimistic(
          state.messages,
          event.clientMessageId,
          sent,
        ),
      ));
    } catch (error) {
      emit(state.copyWith(
        sending: false,
        messages: state.messages
            .map((message) => message.clientMessageId == event.clientMessageId
                ? message.copyWith(pending: false, failed: true)
                : message)
            .toList(),
        error: error.toString(),
      ));
    }
  }

  Future<void> _onCallback(
    SupportCallbackRequested event,
    Emitter<SupportState> emit,
  ) async {
    final session = state.activeSession;
    if (session == null || state.requestingCallback) return;
    emit(state.copyWith(requestingCallback: true, error: null));
    try {
      await _repository.requestCallback(session.slug, phone: event.phone);
      emit(state.copyWith(
        requestingCallback: false,
        notice: 'Callback requested.',
      ));
      await _refreshThread(emit);
    } catch (error) {
      emit(state.copyWith(
        requestingCallback: false,
        error: error.toString(),
      ));
    }
  }

  Future<void> _onResolve(
    SupportResolveRequested event,
    Emitter<SupportState> emit,
  ) async {
    final session = state.activeSession;
    if (session == null || state.resolving) return;
    emit(state.copyWith(resolving: true, error: null));
    await _stopTyping();
    try {
      await _repository.resolve(session.slug, summary: event.summary);
      emit(state.copyWith(
        resolving: false,
        flowOpen: false,
        ratingScore: 0,
        ratingFeedback: '',
        notice: 'Conversation resolved.',
      ));
      await _refreshThread(emit, resetMessages: true);
    } catch (error) {
      emit(state.copyWith(resolving: false, error: error.toString()));
    }
  }

  Future<void> _onSubmitRating(
    SupportRatingSubmitted event,
    Emitter<SupportState> emit,
  ) async {
    final session = state.latestSession;
    if (session == null ||
        session.isActive ||
        session.rating != null ||
        state.ratingScore < 1 ||
        state.submittingRating) {
      return;
    }
    emit(state.copyWith(submittingRating: true, error: null));
    try {
      await _repository.rate(
        session.slug,
        score: state.ratingScore,
        feedback: state.ratingFeedback,
      );
      emit(state.copyWith(
        submittingRating: false,
        notice: 'Thank you for your feedback.',
      ));
      await _refreshThread(emit, resetMessages: true);
    } catch (error) {
      emit(state.copyWith(
        submittingRating: false,
        error: error.toString(),
      ));
    }
  }

  void _onConnectivityChanged(
    SupportConnectivityChanged event,
    Emitter<SupportState> emit,
  ) {
    emit(state.copyWith(
      connected: event.connected,
      connectionMode: event.connected
          ? _mode(state.payload, live: _realtime.isLive)
          : SupportConnectionMode.offline,
    ));
    _configurePolling();
    if (event.connected) {
      unawaited(_realtime.retry());
      add(const _SupportPollRequested(fullRefresh: true));
    }
  }

  void _onAppResumed(SupportAppResumed event, Emitter<SupportState> emit) {
    if (state.connected) {
      unawaited(_realtime.retry());
      add(const _SupportPollRequested(fullRefresh: true));
    }
  }

  void _onAppPaused(SupportAppPaused event, Emitter<SupportState> emit) {
    unawaited(_stopTyping());
  }

  void _onRealtimeChanged(
    _SupportRealtimeChanged event,
    Emitter<SupportState> emit,
  ) {
    final newMode = _mode(state.payload, live: event.live);
    if (kDebugMode) {
      debugPrint('[SupportBloc] 🟢 Realtime Live Status Changed -> live=${event.live}, ConnectionMode=${newMode.name}');
    }
    emit(state.copyWith(
      connectionMode: newMode,
    ));
    _pollTimer?.cancel();
    _pollTimer = null;
    _configurePolling();
    add(const _SupportPollRequested(fullRefresh: true));
  }

  void _onRealtimeReceived(
    _SupportRealtimeReceived event,
    Emitter<SupportState> emit,
  ) {
    if (kDebugMode) {
      debugPrint('[SupportBloc] 📩 Realtime Event Received by BLoC: "${event.event.name}" Data: ${event.event.data}');
    }
    if (event.event.name == 'support.typing') {
      final role = event.event.data['role']?.toString();
      if (role == 'admin' || role == 'agent') {
        final typing = event.event.data['typing'] == true;
        if (kDebugMode) {
          debugPrint('[SupportBloc] 💬 Agent typing state: $typing (role: $role)');
        }
        _remoteTypingTimer?.cancel();
        if (typing) {
          _remoteTypingTimer = Timer(
            const Duration(seconds: 4),
            () => add(const _SupportRemoteTypingExpired()),
          );
        }
        emit(state.copyWith(remoteTyping: typing));
      }
      return;
    }
    final activity = event.event.data['activity']?.toString();
    if (activity == 'message.deleted' || activity == 'thread.cleared') {
      if (kDebugMode) {
        debugPrint('[SupportBloc] 🗑️ Thread activity "$activity" -> Triggering full poll refresh');
      }
      add(const _SupportPollRequested(fullRefresh: true));
      return;
    }
    if (event.event.name == 'support.activity') {
      final record = event.event.data['message'];
      if (record is Map) {
        final message = SupportMessage.fromJson(
          Map<String, dynamic>.from(record),
        );
        if (kDebugMode) {
          debugPrint('[SupportBloc] 📩 New Realtime Message Created: id=${message.id}, text="${message.text}"');
        }
        if (state.thread?.sessions.any(
              (session) => session.id == message.sessionId,
            ) ==
            true) {
          emit(state.copyWith(
            messages: _mergeMessages(state.messages, [message]),
            messageCursor: message.id > state.messageCursor
                ? message.id
                : state.messageCursor,
          ));
          unawaited(_markLatestRead());
          return;
        }
      }
    }
    add(const _SupportPollRequested());
  }

  Future<void> _onPoll(
    _SupportPollRequested event,
    Emitter<SupportState> emit,
  ) async {
    _fullRefreshRequested = _fullRefreshRequested || event.fullRefresh;
    if (_polling || state.payload == null) return;
    _polling = true;
    try {
      if (!_realtime.isLive) {
        unawaited(_realtime.retry());
      }
      final shouldReset = _fullRefreshRequested || !_realtime.isLive;
      _fullRefreshRequested = false;
      await _refreshThread(
        emit,
        resetMessages: shouldReset,
      );
    } catch (_) {
      if (!_realtime.isLive) {
        emit(state.copyWith(connectionMode: SupportConnectionMode.offline));
      }
    } finally {
      _polling = false;
      if (_fullRefreshRequested && !_closing) {
        add(const _SupportPollRequested(fullRefresh: true));
      }
    }
  }

  void _onTypingStopped(
    _SupportTypingStopped event,
    Emitter<SupportState> emit,
  ) {
    unawaited(_stopTyping());
  }

  void _sendTyping(bool typing) {
    if (_typingSent == typing) return;
    final session = state.activeSession;
    if (session == null) return;
    _typingSent = typing;
    _realtime.whisperTyping(typing);
    unawaited(_setTypingSafely(session.slug, typing));
  }

  Future<void> _setTypingSafely(String slug, bool typing) async {
    try {
      await _repository.setTyping(slug, typing);
    } catch (_) {}
  }

  Future<void> _stopTyping() async {
    _typingTimer?.cancel();
    _remoteTypingTimer?.cancel();
    if (!_typingSent) return;
    final session = state.activeSession;
    _typingSent = false;
    _realtime.whisperTyping(false);
    if (session != null) {
      try {
        await _repository.setTyping(session.slug, false);
      } catch (_) {}
    }
  }

  Future<void> _markLatestRead() async {
    final session = state.activeSession;
    if (session == null) return;
    final serverMessages = state.messages.where((message) => message.id > 0);
    final id = serverMessages.isEmpty
        ? null
        : serverMessages
            .map((message) => message.id)
            .reduce((a, b) => a > b ? a : b);
    try {
      await _repository.markRead(session.slug, id);
    } catch (_) {}
  }

  void _configurePolling() {
    final payload = state.payload;
    if (payload == null || _closing) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    // When live, poll every 10s as a safety backup. When not live, poll every 4s.
    final intervalMs = _realtime.isLive
        ? 10000
        : (payload.pollIntervalMs > 0 && payload.pollIntervalMs < 4000
            ? payload.pollIntervalMs
            : 4000);

    if (_pollTimer != null && _pollTimer!.isActive) {
      return;
    }
    _pollTimer?.cancel();
    if (kDebugMode) {
      debugPrint('[SupportBloc] Starting polling every ${intervalMs}ms (live: ${_realtime.isLive})');
    }
    _pollTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) => add(const _SupportPollRequested()),
    );
  }

  SupportConnectionMode _mode(
    SupportThreadPayload? payload, {
    required bool live,
  }) {
    if (live) return SupportConnectionMode.live;
    if (state.connected) {
      return SupportConnectionMode.polling;
    }
    return SupportConnectionMode.offline;
  }

  int _lastMessageId(List<SupportMessage> messages) =>
      messages.where((message) => message.id > 0).fold(
          0, (current, message) => message.id > current ? message.id : current);

  int _lastCallId(List<SupportSession> sessions) => sessions
      .expand((session) => session.calls)
      .fold(0, (current, call) => call.id > current ? call.id : current);

  List<SupportMessage> _mergeMessages(
    List<SupportMessage> first,
    List<SupportMessage> second,
  ) {
    final byKey = <String, SupportMessage>{};
    final committedClients = [...first, ...second]
        .where((message) => message.id > 0 && message.clientMessageId != null)
        .map((message) => message.clientMessageId)
        .toSet();
    for (final message in [...first, ...second]) {
      if (message.id <= 0 &&
          committedClients.contains(message.clientMessageId)) {
        continue;
      }
      final key = message.id > 0
          ? 'id:${message.id}'
          : 'client:${message.clientMessageId ?? message.id}';
      final clientKey = message.clientMessageId == null
          ? null
          : 'client:${message.clientMessageId}';
      if (message.id > 0 && clientKey != null) byKey.remove(clientKey);
      byKey[key] = message;
    }
    final result = byKey.values.toList();
    result.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final dateCompare = aDate.compareTo(bDate);
      return dateCompare != 0 ? dateCompare : a.id.compareTo(b.id);
    });
    return result;
  }

  List<SupportMessage> _replaceOptimistic(
    List<SupportMessage> messages,
    String clientId,
    SupportMessage sent,
  ) =>
      _mergeMessages(
        messages
            .where((message) => message.clientMessageId != clientId)
            .toList(),
        [sent],
      );

  @override
  Future<void> close() async {
    _closing = true;
    _pollTimer?.cancel();
    _typingTimer?.cancel();
    await _stopTyping();
    await _liveSubscription.cancel();
    await _eventSubscription.cancel();
    await _realtime.dispose();
    await super.close();
    for (final file in _temporaryAttachments) {
      await removeSupportDrop(file);
    }
  }
}
