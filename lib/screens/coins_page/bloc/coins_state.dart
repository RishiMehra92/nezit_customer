part of 'coins_bloc.dart';

enum ApiStatus { initial, loading, success, failure }

class CoinsState extends Equatable {
  final ApiStatus status;
  final CoinsSummaryModel? summary;
  final List<LoyaltyTransaction> transactions;
  final int currentPage;
  final bool hasReachedMax;
  final bool isLoadingMore;
  final String? error;

  const CoinsState({
    this.status = ApiStatus.initial,
    this.summary,
    this.transactions = const [],
    this.currentPage = 1,
    this.hasReachedMax = false,
    this.isLoadingMore = false,
    this.error,
  });

  CoinsState copyWith({
    ApiStatus? status,
    CoinsSummaryModel? summary,
    List<LoyaltyTransaction>? transactions,
    int? currentPage,
    bool? hasReachedMax,
    bool? isLoadingMore,
    String? error,
  }) {
    return CoinsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      transactions: transactions ?? this.transactions,
      currentPage: currentPage ?? this.currentPage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
        status,
        summary,
        transactions,
        currentPage,
        hasReachedMax,
        isLoadingMore,
        error,
      ];
}
