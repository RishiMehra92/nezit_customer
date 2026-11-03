part of 'settings_bloc.dart';

abstract class SettingsState extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final SettingsResponse settingsResponse;
  SettingsLoaded({required this.settingsResponse});
  @override
  
  List<Object?> get props => [settingsResponse];
}

class MaintenanceModeEnabled extends SettingsState {
  final String maintenanceModeMessage;

  MaintenanceModeEnabled({required this.maintenanceModeMessage});

  @override
  
  List<Object?> get props => [maintenanceModeMessage];
}

class SettingsFailure extends SettingsState {
  final String error;
  SettingsFailure({required this.error});

  @override
  
  List<Object?> get props => [error];
}