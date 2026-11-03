import 'package:equatable/equatable.dart';

abstract class UserVerificationEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class VerifyUser extends UserVerificationEvent {
  final String type;
  final String value;
  VerifyUser({required this.type, required this.value});
  @override
  
  List<Object?> get props => [type, value];
}

class ResetVerification extends UserVerificationEvent {}