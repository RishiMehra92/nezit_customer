part of 're_order_bloc.dart';

abstract class ReOrderState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class ReOrderInitial extends ReOrderState {}

class ReOrderInProgress extends ReOrderState {}

class ReOrderedSuccess extends ReOrderState {}

class ReOrderedFailed extends ReOrderState {
  final List<String> errorList;
  ReOrderedFailed({required this.errorList});
  @override
  
  List<Object?> get props => [errorList];
}
