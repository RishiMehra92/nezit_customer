part of 'prepare_recharge_bloc.dart';

abstract class PrepareRechargeState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class PrepareRechargeInitial extends PrepareRechargeState {}

class PrepareRechargeLoading extends PrepareRechargeState {}

class PrepareRechargeSuccess extends PrepareRechargeState {
  final String orderId;
  final String amount;
  final String currency;

  PrepareRechargeSuccess({
    required this.orderId,
    required this.amount,
    required this.currency,
  });

  @override
  
  List<Object?> get props => [orderId, amount, currency];
}

class PrepareRechargeFailure extends PrepareRechargeState {
  final String error;
  PrepareRechargeFailure({required this.error});
  @override
  
  List<Object?> get props => [error];
}