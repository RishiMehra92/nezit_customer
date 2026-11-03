part of 'coins_bloc.dart';

abstract class CoinsEvent extends Equatable {
  const CoinsEvent();

  @override
  List<Object?> get props => [];
}

class FetchCoinsSummary extends CoinsEvent {}

class FetchMoreCoinsSummary extends CoinsEvent {}
