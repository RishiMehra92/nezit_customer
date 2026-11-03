part of 'order_detail_bloc.dart';

abstract class OrderDetailEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class FetchOrderDetail extends OrderDetailEvent {
  final String orderSlug;

  FetchOrderDetail({
    required this.orderSlug,
  });

  @override
  
  List<Object?> get props => [orderSlug];
}

class RescheduleOrder extends OrderDetailEvent {
  final int orderId;
  final String orderSlug;
  final String date;
  final String startTime;
  final String endTime;

  RescheduleOrder({
    required this.orderId,
    required this.orderSlug,
    required this.date,
    required this.startTime,
    required this.endTime,
  });

  @override
  List<Object?> get props => [orderId, orderSlug, date, startTime, endTime];
}

class CancelOrder extends OrderDetailEvent {
  final int orderId;
  final String orderSlug;

  CancelOrder({
    required this.orderId,
    required this.orderSlug,
  });

  @override
  List<Object?> get props => [orderId, orderSlug];
}

class PayOrderTip extends OrderDetailEvent {
  final String orderSlug;
  final double riderTipAmount;
  final String paymentMethod;
  final String? transactionId;

  PayOrderTip({
    required this.orderSlug,
    required this.riderTipAmount,
    required this.paymentMethod,
    this.transactionId,
  });

  @override
  List<Object?> get props => [orderSlug, riderTipAmount, paymentMethod, transactionId];
}


