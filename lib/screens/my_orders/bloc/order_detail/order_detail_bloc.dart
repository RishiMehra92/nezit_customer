import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../model/order_detail_model.dart';
import '../../repo/order_repo.dart';
part 'order_detail_event.dart';
part 'order_detail_state.dart';

class OrderDetailBloc extends Bloc<OrderDetailEvent, OrderDetailState> {
  OrderDetailBloc() : super(OrderDetailInitial()) {
    on<FetchOrderDetail>(_onFetchUserCart);
    on<RescheduleOrder>(_onRescheduleOrder);
    on<CancelOrder>(_onCancelOrder);
    on<PayOrderTip>(_onPayOrderTip);
  }

  final OrderRepository repository = OrderRepository();

  Future<void> _onFetchUserCart(FetchOrderDetail event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailLoading());
    try{
      final orderDetailData = await repository.getOrderDetail(
        orderSlug: event.orderSlug,
      );
      if(orderDetailData.first.success == true) {
        emit(OrderDetailLoaded(
          cartData: orderDetailData,
          message: orderDetailData.first.message ?? ''
        ));
      }
    }catch (e) {
      emit(OrderDetailFailed(error: e.toString()));
    }
  }

  Future<void> _onRescheduleOrder(RescheduleOrder event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailActionLoading());
    try {
      final msg = await repository.rescheduleOrder(
        orderId: event.orderId,
        date: event.date,
        startTime: event.startTime,
        endTime: event.endTime,
      );
      emit(OrderDetailActionSuccess(
        message: msg ?? 'Order rescheduled successfully',
        actionType: 'reschedule',
      ));
      final orderDetailData = await repository.getOrderDetail(
        orderSlug: event.orderSlug,
      );
      if(orderDetailData.first.success == true) {
        emit(OrderDetailLoaded(
          cartData: orderDetailData,
          message: orderDetailData.first.message ?? ''
        ));
      }
    } catch (e) {
      emit(OrderDetailActionFailed(error: e.toString()));
    }
  }

  Future<void> _onCancelOrder(CancelOrder event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailActionLoading());
    try {
      final msg = await repository.cancelOrder(
        orderId: event.orderId,
      );
      emit(OrderDetailActionSuccess(
        message: msg ?? 'Order cancelled successfully',
        actionType: 'cancel',
      ));
      final orderDetailData = await repository.getOrderDetail(
        orderSlug: event.orderSlug,
      );
      if(orderDetailData.first.success == true) {
        emit(OrderDetailLoaded(
          cartData: orderDetailData,
          message: orderDetailData.first.message ?? ''
        ));
      }
    } catch (e) {
      emit(OrderDetailActionFailed(error: e.toString()));
    }
  }

  Future<void> _onPayOrderTip(PayOrderTip event, Emitter<OrderDetailState> emit) async {
    emit(OrderDetailActionLoading());
    try {
      final response = await repository.payOrderTip(
        orderSlug: event.orderSlug,
        riderTipAmount: event.riderTipAmount,
        paymentMethod: event.paymentMethod,
        transactionId: event.transactionId,
      );

      if (response['success'] == true) {
        emit(OrderDetailActionSuccess(
          message: response['message'] ?? 'Tip paid successfully',
          actionType: 'pay_tip',
        ));
      } else {
        emit(OrderDetailActionFailed(error: response['message']?.toString() ?? 'Failed to pay tip'));
      }
    } catch (e) {
      emit(OrderDetailActionFailed(error: e.toString()));
    }
  }
}