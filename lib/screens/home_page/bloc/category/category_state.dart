import 'package:equatable/equatable.dart';
import 'package:hyper_local/screens/home_page/model/category_model.dart';

abstract class CategoryState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class CategoryInitial extends CategoryState {}

class CategoryLoading extends CategoryState {}

class CategoryLoaded extends CategoryState {
  final List<CategoryData> categoryData;
  final String message;
  final bool hasReachedMax;
  CategoryLoaded({
    required this.message,
    required this.categoryData,
    required this.hasReachedMax
  });

  @override
  
  List<Object?> get props => [message, categoryData, hasReachedMax];
}

class CategoryFailed extends CategoryState {
  final String error;
  CategoryFailed({required this.error});

  @override
  
  List<Object?> get props => [error];
}