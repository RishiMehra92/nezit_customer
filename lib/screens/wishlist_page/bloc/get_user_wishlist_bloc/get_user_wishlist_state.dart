import 'package:equatable/equatable.dart';
import 'package:hyper_local/utils/api_status.dart';
import '../../model/user_wishlist_model.dart';

class UserWishlistState extends Equatable {
  final ApiStatus status;
  final String message;
  final String error;
  final List<WishlistData> wishlistData;
  final bool hasReachedMax;

  const UserWishlistState({
    this.status = ApiStatus.initial,
    this.message = '',
    this.error = '',
    this.wishlistData = const [],
    this.hasReachedMax = false,
  });

  UserWishlistState copyWith({
    ApiStatus? status,
    String? message,
    String? error,
    List<WishlistData>? wishlistData,
    bool? hasReachedMax,
  }) {
    return UserWishlistState(
      status: status ?? this.status,
      message: message ?? this.message,
      error: error ?? this.error,
      wishlistData: wishlistData ?? this.wishlistData,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, message, error, wishlistData, hasReachedMax];
}
