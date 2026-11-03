import 'package:equatable/equatable.dart';

abstract class GetMyOrderEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchMyOrder extends GetMyOrderEvent {
  final String? dateFilter;
  final String? statusSort;
  final String? deliveryType;
  final int? isScheduled;
  FetchMyOrder({this.dateFilter, this.statusSort, this.deliveryType, this.isScheduled});
  @override
  
  List<Object?> get props => [dateFilter, statusSort, deliveryType, isScheduled];
}

class FetchMoreMyOrder extends GetMyOrderEvent {
  final String? dateFilter;
  final String? statusSort;
  final String? deliveryType;
  final int? isScheduled;
  FetchMoreMyOrder({this.dateFilter, this.statusSort, this.deliveryType, this.isScheduled});
  @override
  
  List<Object?> get props => [dateFilter, statusSort, deliveryType, isScheduled];
}

class RefreshMyOrders extends GetMyOrderEvent {
  final String? dateFilter;
  final String? statusSort;
  final String? deliveryType;
  final int? isScheduled;
  RefreshMyOrders({this.dateFilter, this.statusSort, this.deliveryType, this.isScheduled});
  @override
  
  List<Object?> get props => [dateFilter, statusSort, deliveryType, isScheduled];
}

class UpdateDateFilter extends GetMyOrderEvent {
  final String dateFilter;
  UpdateDateFilter({required this.dateFilter});

  @override
  
  List<Object?> get props => [dateFilter];
}

class UpdateStatusFilter extends GetMyOrderEvent {
  final String statusFilter;
  UpdateStatusFilter({required this.statusFilter});

  @override
  
  List<Object?> get props => [statusFilter];
}

class ClearDateFilter extends GetMyOrderEvent {}

class ClearStatusFilter extends GetMyOrderEvent {}