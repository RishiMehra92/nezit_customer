import 'package:equatable/equatable.dart';

abstract class ClearCartEvent extends Equatable {
  @override
  
  List<Object?> get props => [];
}

class ClearCartRequest extends ClearCartEvent{}