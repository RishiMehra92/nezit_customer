part of 'support_bloc.dart';

sealed class SupportEvent extends Equatable {
  const SupportEvent();

  @override
  List<Object?> get props => const [];
}

class SupportStarted extends SupportEvent {
  const SupportStarted({this.initialOrderId});

  final int? initialOrderId;

  @override
  List<Object?> get props => [initialOrderId];
}

class SupportRefreshRequested extends SupportEvent {
  const SupportRefreshRequested();
}

class SupportLoadOlderRequested extends SupportEvent {
  const SupportLoadOlderRequested();
}

class SupportFlowOpened extends SupportEvent {
  const SupportFlowOpened();
}

class SupportFlowClosed extends SupportEvent {
  const SupportFlowClosed();
}

class SupportFlowBackRequested extends SupportEvent {
  const SupportFlowBackRequested();
}

class SupportOrderSelected extends SupportEvent {
  const SupportOrderSelected(this.orderId);

  final int? orderId;

  @override
  List<Object?> get props => [orderId];
}

class SupportTopicSelected extends SupportEvent {
  const SupportTopicSelected(this.topicId);

  final int topicId;

  @override
  List<Object?> get props => [topicId];
}

class SupportDraftChanged extends SupportEvent {
  const SupportDraftChanged(this.value);

  final String value;

  @override
  List<Object?> get props => [value];
}

class SupportAttachmentsSelected extends SupportEvent {
  const SupportAttachmentsSelected(this.attachments);

  final List<SupportLocalAttachment> attachments;

  @override
  List<Object?> get props => [attachments];
}

class SupportAttachmentRemoved extends SupportEvent {
  const SupportAttachmentRemoved(this.path);

  final String path;

  @override
  List<Object?> get props => [path];
}

class SupportStartSessionRequested extends SupportEvent {
  const SupportStartSessionRequested();
}

class SupportSendRequested extends SupportEvent {
  const SupportSendRequested();
}

class SupportRetryMessageRequested extends SupportEvent {
  const SupportRetryMessageRequested(this.clientMessageId);

  final String clientMessageId;

  @override
  List<Object?> get props => [clientMessageId];
}

class SupportCallbackRequested extends SupportEvent {
  const SupportCallbackRequested({this.phone});

  final String? phone;

  @override
  List<Object?> get props => [phone];
}

class SupportResolveRequested extends SupportEvent {
  const SupportResolveRequested({this.summary});

  final String? summary;

  @override
  List<Object?> get props => [summary];
}

class SupportRatingScoreChanged extends SupportEvent {
  const SupportRatingScoreChanged(this.score);

  final int score;

  @override
  List<Object?> get props => [score];
}

class SupportRatingFeedbackChanged extends SupportEvent {
  const SupportRatingFeedbackChanged(this.feedback);

  final String feedback;

  @override
  List<Object?> get props => [feedback];
}

class SupportRatingSubmitted extends SupportEvent {
  const SupportRatingSubmitted();
}

class SupportConnectivityChanged extends SupportEvent {
  const SupportConnectivityChanged(this.connected);

  final bool connected;

  @override
  List<Object?> get props => [connected];
}

class SupportAppResumed extends SupportEvent {
  const SupportAppResumed();
}

class SupportAppPaused extends SupportEvent {
  const SupportAppPaused();
}

class SupportFeedbackConsumed extends SupportEvent {
  const SupportFeedbackConsumed();
}

class _SupportRealtimeChanged extends SupportEvent {
  const _SupportRealtimeChanged(this.live);

  final bool live;

  @override
  List<Object?> get props => [live];
}

class _SupportRealtimeReceived extends SupportEvent {
  const _SupportRealtimeReceived(this.event);

  final SupportRealtimeEvent event;

  @override
  List<Object?> get props => [event];
}

class _SupportPollRequested extends SupportEvent {
  const _SupportPollRequested({this.fullRefresh = false});

  final bool fullRefresh;

  @override
  List<Object?> get props => [fullRefresh];
}

class _SupportTypingStopped extends SupportEvent {
  const _SupportTypingStopped();
}

class _SupportRemoteTypingExpired extends SupportEvent {
  const _SupportRemoteTypingExpired();
}
