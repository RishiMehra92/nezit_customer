part of 'wallet_transactions_bloc.dart';

abstract class WalletTransactionsEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchWalletTransactions extends WalletTransactionsEvent {
  @override
  
  List<Object?> get props => [];
}

class FetchMoreWalletTransactions extends WalletTransactionsEvent {}