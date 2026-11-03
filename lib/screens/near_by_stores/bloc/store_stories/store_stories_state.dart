import 'package:equatable/equatable.dart';
import 'package:hyper_local/utils/api_status.dart';
import 'package:hyper_local/screens/discover_page/model/discover_status_model.dart';

class StoreStoriesState extends Equatable {
  final ApiStatus status;
  final List<DiscoverStatusItem> items;
  final String? errorMessage;

  const StoreStoriesState({
    this.status = ApiStatus.initial,
    this.items = const [],
    this.errorMessage,
  });

  StoreStoriesState copyWith({
    ApiStatus? status,
    List<DiscoverStatusItem>? items,
    String? errorMessage,
  }) {
    return StoreStoriesState(
      status: status ?? this.status,
      items: items ?? this.items,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        errorMessage,
      ];
}
