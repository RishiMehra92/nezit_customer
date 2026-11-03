part of 'return_order_item_bloc.dart';

abstract class ReturnOrderItemEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class ReturnOrderItemRequest extends ReturnOrderItemEvent {
  final int orderItemId;
  final int? returnReasonId;
  final String reason;
  final List<XFile> images;

  ReturnOrderItemRequest({
    required this.orderItemId,
    this.returnReasonId,
    required this.reason,
    this.images = const [],
  });

  @override
  
  List<Object?> get props => [orderItemId, returnReasonId, reason, images];
}

class CancelReturnRequest extends ReturnOrderItemEvent {
  final int orderItemId;

  CancelReturnRequest({required this.orderItemId});

  @override
  
  List<Object?> get props => [orderItemId];
}

class CancelOrderItem extends ReturnOrderItemEvent {
  final int orderItemId;

  CancelOrderItem({
    required this.orderItemId,
  });

  @override
  
  List<Object?> get props => [orderItemId];
}

class FetchReturnReasons extends ReturnOrderItemEvent {
  final int orderItemId;

  FetchReturnReasons({required this.orderItemId});

  @override
  List<Object?> get props => [orderItemId];
}