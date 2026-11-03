import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../cart_page/widgets/cart_product_item.dart';
import '../../repo/order_repo.dart';

part 'create_order_event.dart';
part 'create_order_state.dart';

class CreateOrderBloc extends Bloc<CreateOrderEvent, CreateOrderState> {
  CreateOrderBloc() : super(CreateOrderInitial()) {
    on<CreateOrderRequest>(_onCreateOrderRequest);
  }
  final OrderRepository repository = OrderRepository();

  bool isLoading = false;

  Future<void> _onCreateOrderRequest(CreateOrderRequest event, Emitter<CreateOrderState> emit) async {
    emit(CreateOrderProgress());
    isLoading = true;
    try{
      final response = await repository.createOrder(
        paymentType: event.paymentType,
        promoCode: event.promoCode ?? '',
        giftCard: event.giftCard ?? '',
        addressId: event.addressId,
        rushDelivery: event.rushDelivery ?? false,
        useWallet: event.useWallet ?? false,
        orderNote: event.orderNote ?? '',
        paymentDetails: event.paymentDetails,
        attachments: event.attachments!,
        deliveryType: event.deliveryType ?? 'delivery',
        scheduledDate: event.scheduledDate,
        scheduledTimeSlotLabel: event.scheduledTimeSlotLabel,
        scheduledSlotStartTime: event.scheduledSlotStartTime,
        scheduledSlotEndTime: event.scheduledSlotEndTime,
      );

      if (response['success'] == true) {
        isLoading = false;
        final data = response['data'];
        final paymentResponse = data is Map ? data['payment_response'] : null;
        final paymentLink = paymentResponse is Map
            ? (paymentResponse['init_point']?.toString() ??
               paymentResponse['sandbox_init_point']?.toString() ??
               paymentResponse['link']?.toString() ??
               paymentResponse['checkout_url']?.toString() ??
               paymentResponse['invoice_url']?.toString() ??
               paymentResponse['url']?.toString())
            : (data is Map
                ? (data['init_point']?.toString() ??
                   data['sandbox_init_point']?.toString() ??
                   data['link']?.toString() ??
                   data['checkout_url']?.toString() ??
                   data['invoice_url']?.toString() ??
                   data['url']?.toString())
                : null);

        emit(CreateOrderSuccess(
          message: response['message']?.toString() ?? '',
          orderSlug: (data is Map ? data['slug']?.toString() : null) ?? '',
          paymentUrl: (event.paymentType == 'flutterwave' ||
                  event.paymentType == 'xendit' ||
                  event.paymentType.toLowerCase().contains('mercadopago'))
              ? paymentLink
              : '',
          transactionUuid: (data is Map ? data['transaction_uuid']?.toString() : null),
        ));
      } else {
        emit(CreateOrderFailure(error: response['message']?.toString() ?? 'Failed to place order'));
      }
    } catch(e) {
      isLoading = false;
      emit(CreateOrderFailure(error: e.toString()));
    }
  }
}
