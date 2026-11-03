part of 'device_sync_bloc.dart';

abstract class DeviceSyncEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class SyncDevice extends DeviceSyncEvent {
  final String deviceType;
  final String previousToken;
  final String roleType;

  SyncDevice({
    required this.deviceType,
    required this.previousToken,
    required this.roleType,
  });

  @override
  
  List<Object?> get props => [deviceType, previousToken, roleType];
}