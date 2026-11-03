part of 'order_detail_bloc.dart';

abstract class OrderDetailState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class OrderDetailInitial extends OrderDetailState {}

class OrderDetailLoading extends OrderDetailState {}

class OrderDetailLoaded extends OrderDetailState {
  final List<OrderDetailModel> cartData;
  final String message;
  OrderDetailLoaded({required this.cartData, required this.message,});
  @override
  
  List<Object?> get props => [cartData, message];
}

class OrderDetailFailed extends OrderDetailState {
  final String error;
  OrderDetailFailed({required this.error});
  @override
  
  List<Object?> get props => [error];
}

class OrderDetailActionLoading extends OrderDetailState {}

class OrderDetailActionSuccess extends OrderDetailState {
  final String message;
  final String actionType;
  
  OrderDetailActionSuccess({required this.message, required this.actionType});

  @override
  List<Object?> get props => [message, actionType];
}

class OrderDetailActionFailed extends OrderDetailState {
  final String error;
  OrderDetailActionFailed({required this.error});

  @override
  List<Object?> get props => [error];
}

