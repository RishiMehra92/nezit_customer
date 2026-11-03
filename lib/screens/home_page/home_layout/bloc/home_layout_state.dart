import 'package:equatable/equatable.dart';
import '../model/home_layout_models.dart';

abstract class HomeLayoutState extends Equatable {
  const HomeLayoutState();

  @override
  List<Object?> get props => [];
}

class HomeLayoutInitial extends HomeLayoutState {}

class HomeLayoutLoading extends HomeLayoutState {}

class HomeLayoutLoaded extends HomeLayoutState {
  final String message;
  final String scopeType;
  final List<HomeSection> sections;
  final bool hasReachedMax;
  final bool isLoadingMore;

  const HomeLayoutLoaded({
    required this.message,
    required this.scopeType,
    required this.sections,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
  });

  HomeLayoutLoaded copyWith({
    String? message,
    String? scopeType,
    List<HomeSection>? sections,
    bool? hasReachedMax,
    bool? isLoadingMore,
  }) {
    return HomeLayoutLoaded(
      message: message ?? this.message,
      scopeType: scopeType ?? this.scopeType,
      sections: sections ?? this.sections,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }

  @override
  List<Object?> get props => [message, scopeType, sections, hasReachedMax, isLoadingMore];
}

class HomeLayoutFailed extends HomeLayoutState {
  final String error;
  const HomeLayoutFailed({required this.error});

  @override
  List<Object?> get props => [error];
}
