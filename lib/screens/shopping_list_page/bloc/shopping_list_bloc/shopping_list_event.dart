part of 'shopping_list_bloc.dart';

abstract class ShoppingListEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class CreateShoppingList extends ShoppingListEvent {
  final String keywords;
  CreateShoppingList({required this.keywords});
  @override
  
  List<Object?> get props => [keywords];
}