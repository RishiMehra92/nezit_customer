part of 'delivery_zone_detail_bloc.dart';

abstract class DeliveryZoneDetailEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}


class FetchDeliveryZoneDetail extends DeliveryZoneDetailEvent {
  final int zoneId;

  FetchDeliveryZoneDetail({required this.zoneId});

  @override
  
  List<Object?> get props => [zoneId];
}