part of 'store_detail_bloc.dart';

abstract class StoreDetailEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchStoreDetail extends StoreDetailEvent {
  final String storeSlug;
  final int? isNotify;

  FetchStoreDetail({required this.storeSlug, this.isNotify});

  @override
  List<Object?> get props => [storeSlug, isNotify];
}

class UpdateStoreDetailNotification extends StoreDetailEvent {
  final bool isNotify;

  UpdateStoreDetailNotification({required this.isNotify});

  @override
  List<Object?> get props => [isNotify];
}

