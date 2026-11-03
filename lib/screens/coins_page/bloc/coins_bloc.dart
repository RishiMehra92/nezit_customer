import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/coins_page/model/coins_summary_model.dart';
import 'package:hyper_local/screens/coins_page/repo/coins_repository.dart';

part 'coins_event.dart';
part 'coins_state.dart';

class CoinsBloc extends Bloc<CoinsEvent, CoinsState> {
  final CoinsRepository repository = CoinsRepository();

  int currentPage = 1;
  final int perPage = 15;
  bool hasReachedMax = false;
  bool isLoadingMore = false;

  CoinsBloc() : super(const CoinsState()) {
    on<FetchCoinsSummary>(_onFetchCoinsSummary);
    on<FetchMoreCoinsSummary>(_onFetchMoreCoinsSummary);
  }

  Future<void> _onFetchCoinsSummary(
    FetchCoinsSummary event,
    Emitter<CoinsState> emit,
  ) async {
    emit(state.copyWith(status: ApiStatus.loading));
    try {
      currentPage = 1;
      hasReachedMax = false;
      isLoadingMore = false;

      final response = await repository.fetchCoinsSummary(
        page: currentPage,
        perPage: perPage,
      );

      if (response != null) {
        final lastPageNum = response.pagination?.lastPage ?? 1;
        hasReachedMax = currentPage >= lastPageNum || response.transactions.length < perPage;

        emit(state.copyWith(
          status: ApiStatus.success,
          summary: response,
          transactions: response.transactions,
          currentPage: currentPage,
          hasReachedMax: hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        emit(state.copyWith(
          status: ApiStatus.failure,
          error: 'Failed to load loyalty points transactions',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ApiStatus.failure,
        error: e.toString(),
      ));
    }
  }

  Future<void> _onFetchMoreCoinsSummary(
    FetchMoreCoinsSummary event,
    Emitter<CoinsState> emit,
  ) async {
    if (hasReachedMax || isLoadingMore) return;

    isLoadingMore = true;
    emit(state.copyWith(isLoadingMore: true));

    try {
      currentPage += 1;

      final response = await repository.fetchCoinsSummary(
        page: currentPage,
        perPage: perPage,
      );

      if (response != null) {
        final lastPageNum = response.pagination?.lastPage ?? 1;
        hasReachedMax = currentPage >= lastPageNum || response.transactions.length < perPage;

        final updatedTransactions = List<LoyaltyTransaction>.from(state.transactions);
        for (final newTx in response.transactions) {
          if (!updatedTransactions.any((existing) => existing.id == newTx.id)) {
            updatedTransactions.add(newTx);
          }
        }

        emit(state.copyWith(
          status: ApiStatus.success,
          summary: response,
          transactions: updatedTransactions,
          currentPage: currentPage,
          hasReachedMax: hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        currentPage -= 1;
        emit(state.copyWith(
          status: ApiStatus.failure,
          isLoadingMore: false,
          error: 'Failed to load more transactions',
        ));
      }
    } catch (e) {
      currentPage -= 1;
      emit(state.copyWith(
        status: ApiStatus.failure,
        isLoadingMore: false,
        error: e.toString(),
      ));
    } finally {
      isLoadingMore = false;
    }
  }
}
