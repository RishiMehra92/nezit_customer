part of 'store_detail_bloc.dart';

abstract class StoreDetailState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class StoreDetailInitial extends StoreDetailState {}

class StoreDetailLoading extends StoreDetailState {}

class StoreDetailLoaded extends StoreDetailState {
  final StoreData storeData;

  StoreDetailLoaded({required this.storeData});

  @override
  
  List<Object?> get props => [storeData];
}

class StoreDetailFailed extends StoreDetailState {
  final String error;

  StoreDetailFailed({required this.error});

  @override
  
  List<Object?> get props => [error];
}
