part of 'support_bloc.dart';

enum SupportLoadStatus { initial, loading, loaded, failed }

class SupportState extends Equatable {
  const SupportState({
    this.status = SupportLoadStatus.initial,
    this.payload,
    this.topics = const [],
    this.messages = const [],
    this.connectionMode = SupportConnectionMode.offline,
    this.flowOpen = false,
    this.orderSelectionMade = false,
    this.selectedOrderId,
    this.selectedTopicId,
    this.draft = '',
    this.attachments = const [],
    this.messageCursor = 0,
    this.callCursor = 0,
    this.hasMoreMessages = false,
    this.oldestMessageId,
    this.remoteTyping = false,
    this.connected = true,
    this.sending = false,
    this.loadingOlder = false,
    this.resolving = false,
    this.requestingCallback = false,
    this.submittingRating = false,
    this.ratingScore = 0,
    this.ratingFeedback = '',
    this.error,
    this.notice,
  });

  static const _unset = Object();

  final SupportLoadStatus status;
  final SupportThreadPayload? payload;
  final List<SupportTopic> topics;
  final List<SupportMessage> messages;
  final SupportConnectionMode connectionMode;
  final bool flowOpen;
  final bool orderSelectionMade;
  final int? selectedOrderId;
  final int? selectedTopicId;
  final String draft;
  final List<SupportLocalAttachment> attachments;
  final int messageCursor;
  final int callCursor;
  final bool hasMoreMessages;
  final int? oldestMessageId;
  final bool remoteTyping;
  final bool connected;
  final bool sending;
  final bool loadingOlder;
  final bool resolving;
  final bool requestingCallback;
  final bool submittingRating;
  final int ratingScore;
  final String ratingFeedback;
  final String? error;
  final String? notice;

  SupportThread? get thread => payload?.thread;
  SupportSession? get activeSession => thread?.activeSession;
  SupportSession? get latestSession => thread?.latestSession;
  bool get hasActiveSession => activeSession != null;
  bool get canCompose => hasActiveSession && !sending;
  bool get canStartSession =>
      selectedTopicId != null &&
      (draft.trim().isNotEmpty || attachments.isNotEmpty) &&
      !sending;

  List<SupportTopic> get visibleTopics =>
      topics.where((topic) => topic.supports(selectedOrderId != null)).toList();

  SupportTopic? get selectedTopic {
    for (final topic in topics) {
      if (topic.id == selectedTopicId) return topic;
    }
    return null;
  }

  SupportState copyWith({
    SupportLoadStatus? status,
    Object? payload = _unset,
    List<SupportTopic>? topics,
    List<SupportMessage>? messages,
    SupportConnectionMode? connectionMode,
    bool? flowOpen,
    bool? orderSelectionMade,
    Object? selectedOrderId = _unset,
    Object? selectedTopicId = _unset,
    String? draft,
    List<SupportLocalAttachment>? attachments,
    int? messageCursor,
    int? callCursor,
    bool? hasMoreMessages,
    Object? oldestMessageId = _unset,
    bool? remoteTyping,
    bool? connected,
    bool? sending,
    bool? loadingOlder,
    bool? resolving,
    bool? requestingCallback,
    bool? submittingRating,
    int? ratingScore,
    String? ratingFeedback,
    Object? error = _unset,
    Object? notice = _unset,
  }) =>
      SupportState(
        status: status ?? this.status,
        payload: identical(payload, _unset)
            ? this.payload
            : payload as SupportThreadPayload?,
        topics: topics ?? this.topics,
        messages: messages ?? this.messages,
        connectionMode: connectionMode ?? this.connectionMode,
        flowOpen: flowOpen ?? this.flowOpen,
        orderSelectionMade: orderSelectionMade ?? this.orderSelectionMade,
        selectedOrderId: identical(selectedOrderId, _unset)
            ? this.selectedOrderId
            : selectedOrderId as int?,
        selectedTopicId: identical(selectedTopicId, _unset)
            ? this.selectedTopicId
            : selectedTopicId as int?,
        draft: draft ?? this.draft,
        attachments: attachments ?? this.attachments,
        messageCursor: messageCursor ?? this.messageCursor,
        callCursor: callCursor ?? this.callCursor,
        hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
        oldestMessageId: identical(oldestMessageId, _unset)
            ? this.oldestMessageId
            : oldestMessageId as int?,
        remoteTyping: remoteTyping ?? this.remoteTyping,
        connected: connected ?? this.connected,
        sending: sending ?? this.sending,
        loadingOlder: loadingOlder ?? this.loadingOlder,
        resolving: resolving ?? this.resolving,
        requestingCallback: requestingCallback ?? this.requestingCallback,
        submittingRating: submittingRating ?? this.submittingRating,
        ratingScore: ratingScore ?? this.ratingScore,
        ratingFeedback: ratingFeedback ?? this.ratingFeedback,
        error: identical(error, _unset) ? this.error : error as String?,
        notice: identical(notice, _unset) ? this.notice : notice as String?,
      );

  @override
  List<Object?> get props => [
        status,
        payload,
        topics,
        messages,
        connectionMode,
        flowOpen,
        orderSelectionMade,
        selectedOrderId,
        selectedTopicId,
        draft,
        attachments,
        messageCursor,
        callCursor,
        hasMoreMessages,
        oldestMessageId,
        remoteTyping,
        connected,
        sending,
        loadingOlder,
        resolving,
        requestingCallback,
        submittingRating,
        ratingScore,
        ratingFeedback,
        error,
        notice,
      ];
}
