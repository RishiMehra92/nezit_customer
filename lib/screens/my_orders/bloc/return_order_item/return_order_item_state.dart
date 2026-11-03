part of 'return_order_item_bloc.dart';

abstract class ReturnOrderItemState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class ReturnOrderItemInitial extends ReturnOrderItemState {}

class ReturnOrderItemLoading extends ReturnOrderItemState {}

class ReturnOrderItemSuccess extends ReturnOrderItemState {
  final String message;
  ReturnOrderItemSuccess({required this.message});
  @override
  
  List<Object?> get props => [message];
}

class ReturnOrderItemFailed extends ReturnOrderItemState {
  final String error;
  ReturnOrderItemFailed({required this.error});
}

class ReturnReasonsLoading extends ReturnOrderItemState {}

class ReturnReasonsLoaded extends ReturnOrderItemState {
  final List<ReturnReason> reasons;
  ReturnReasonsLoaded({required this.reasons});

  @override
  List<Object?> get props => [reasons];
}

class ReturnReasonsFailed extends ReturnOrderItemState {
  final String error;
  ReturnReasonsFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
