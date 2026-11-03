import 'package:equatable/equatable.dart';

abstract class RemoveItemFromCartState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class RemoveItemFromCartInitial extends RemoveItemFromCartState {}

class RemoveItemFromCartLoading extends RemoveItemFromCartState {}

class RemoveItemFromCartSuccess extends RemoveItemFromCartState {}

class RemoveItemFromCartFailed extends RemoveItemFromCartState {
  final String error;

  RemoveItemFromCartFailed({required this.error});

  @override
  List<Object?> get props => [error];
}