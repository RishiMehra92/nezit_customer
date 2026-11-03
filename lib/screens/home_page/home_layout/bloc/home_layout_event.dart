import 'dart:async';
import 'package:equatable/equatable.dart';

abstract class HomeLayoutEvent extends Equatable {
  const HomeLayoutEvent();

  @override
  List<Object?> get props => [];
}

class FetchHomeLayout extends HomeLayoutEvent {
  final String categorySlug;
  final bool isRefresh;
  final Completer<void>? completer;

  const FetchHomeLayout({
    this.categorySlug = '',
    this.isRefresh = false,
    this.completer,
  });

  @override
  List<Object?> get props => [categorySlug, isRefresh, completer];
}

class FetchMoreHomeLayout extends HomeLayoutEvent {
  const FetchMoreHomeLayout();
}
