import 'package:equatable/equatable.dart';

abstract class PaymentState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {}

class PaymentLoading extends PaymentState {}

class PaymentSuccess extends PaymentState {
  final String transactionId;
  final String message;
  final String signature;
  final String orderId;

  PaymentSuccess({
    required this.transactionId,
    required this.message,
    required this.signature,
    required this.orderId,
  });

  @override
  
  List<Object?> get props => [transactionId, message, signature, orderId];
}

class PaymentFailure extends PaymentState {
  final String error;

  PaymentFailure({required this.error});

  @override
  
  List<Object?> get props => [error];
}
