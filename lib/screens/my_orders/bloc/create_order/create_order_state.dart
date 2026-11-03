part of 'create_order_bloc.dart';

abstract class CreateOrderState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class CreateOrderInitial extends CreateOrderState {}

class CreateOrderProgress extends CreateOrderState {}

class CreateOrderSuccess extends CreateOrderState {
  final String message;
  final String orderSlug;
  final String? paymentUrl;
  final String? transactionUuid;

  CreateOrderSuccess({required this.message, required this.orderSlug, required this.paymentUrl, this.transactionUuid});
  @override
  
  List<Object?> get props => [message, orderSlug, paymentUrl, transactionUuid];
}

class CreateOrderFailure extends CreateOrderState {
  final String error;
  CreateOrderFailure({required this.error});
  @override
  
  List<Object?> get props => [error];
}
