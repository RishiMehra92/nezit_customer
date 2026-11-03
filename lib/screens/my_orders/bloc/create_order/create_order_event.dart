part of 'create_order_bloc.dart';

abstract class CreateOrderEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class CreateOrderRequest extends CreateOrderEvent {
  final String paymentType;
  final String? promoCode;
  final String? giftCard;
  final int? addressId;
  final bool? rushDelivery;
  final bool? useWallet;
  final String? orderNote;
  final Map<String, dynamic>? paymentDetails;
  final Map<int, List<CartItemAttachment>>? attachments;
  final String? deliveryType;
  final String? scheduledDate;
  final String? scheduledTimeSlotLabel;
  final String? scheduledSlotStartTime;
  final String? scheduledSlotEndTime;

  CreateOrderRequest({
    required this.paymentType,
    this.promoCode,
    this.giftCard,
    this.addressId,
    this.rushDelivery,
    this.useWallet,
    this.orderNote,
    this.paymentDetails,
    this.attachments,
    this.deliveryType,
    this.scheduledDate,
    this.scheduledTimeSlotLabel,
    this.scheduledSlotStartTime,
    this.scheduledSlotEndTime,
  });

  @override
  
  List<Object?> get props => [
    paymentType,
    promoCode,
    giftCard,
    addressId,
    rushDelivery,
    useWallet,
    orderNote,
    paymentDetails,
    attachments,
    deliveryType,
    scheduledDate,
    scheduledTimeSlotLabel,
    scheduledSlotStartTime,
    scheduledSlotEndTime,
  ];
}
