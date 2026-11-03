import 'package:equatable/equatable.dart';

abstract class SaveForLaterEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchSavedProducts extends SaveForLaterEvent {}

class FetchMoreSavedProducts extends SaveForLaterEvent {}


class SaveForLaterRequest extends SaveForLaterEvent {
  final int cartItemId;
  final String cartItemName;

  SaveForLaterRequest({required this.cartItemId, required this.cartItemName});
  @override
  
  List<Object?> get props => [cartItemId, cartItemName];
}
