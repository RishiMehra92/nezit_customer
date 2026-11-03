import 'package:flutter_bloc/flutter_bloc.dart';
import '../model/home_layout_models.dart';
import '../repo/home_layout_repo.dart';
import 'home_layout_event.dart';
import 'home_layout_state.dart';

class HomeLayoutBloc extends Bloc<HomeLayoutEvent, HomeLayoutState> {
  final HomeLayoutRepository repository = HomeLayoutRepository();
  static const int _perPage = 5;

  int _currentPage = 1;
  bool _hasReachedMax = false;
  bool _isLoadingMore = false;
  String _categorySlug = '';
  String _message = '';
  String _scopeType = 'global';
  final List<HomeSection> _sections = [];
  int _fetchRequestId = 0;

  HomeLayoutBloc() : super(HomeLayoutInitial()) {
    on<FetchHomeLayout>(_onFetchHomeLayout);
    on<FetchMoreHomeLayout>(_onFetchMoreHomeLayout);
  }

  Future<void> _onFetchHomeLayout(
    FetchHomeLayout event,
    Emitter<HomeLayoutState> emit,
  ) async {
    final myRequestId = ++_fetchRequestId;
    if (!event.isRefresh) {
      emit(HomeLayoutLoading());
    }
    _currentPage = 1;
    _hasReachedMax = false;
    _isLoadingMore = false;
    _categorySlug = event.categorySlug;
    if (!event.isRefresh) {
      _sections.clear();
    }
    try {
      final raw = await repository.fetchHomeLayout(
        categorySlug: _categorySlug,
        page: _currentPage,
        perPage: _perPage,
      );

      if (myRequestId != _fetchRequestId) {
        if (event.completer != null && !event.completer!.isCompleted) {
          event.completer!.complete();
        }
        return;
      }

      final response = HomeLayoutResponse.fromJson(raw);
      if (response.success) {
        _message = response.message;
        _scopeType = response.scopeType;
        _sections
          ..clear()
          ..addAll(response.sections);
        _hasReachedMax = response.sections.length < _perPage;
        emit(HomeLayoutLoaded(
          message: _message,
          scopeType: _scopeType,
          sections: List.of(_sections),
          hasReachedMax: _hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        emit(HomeLayoutFailed(error: response.message));
      }
    } catch (e) {
      if (myRequestId != _fetchRequestId) {
        if (event.completer != null && !event.completer!.isCompleted) {
          event.completer!.complete();
        }
        return;
      }
      emit(HomeLayoutFailed(error: e.toString()));
    } finally {
      if (event.completer != null && !event.completer!.isCompleted) {
        event.completer!.complete();
      }
    }
  }

  Future<void> _onFetchMoreHomeLayout(
    FetchMoreHomeLayout event,
    Emitter<HomeLayoutState> emit,
  ) async {
    if (_hasReachedMax || _isLoadingMore) return;
    final current = state;
    if (current is! HomeLayoutLoaded) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = _currentPage + 1;
      final raw = await repository.fetchHomeLayout(
        categorySlug: _categorySlug,
        page: nextPage,
        perPage: _perPage,
      );
      final response = HomeLayoutResponse.fromJson(raw);
      if (response.success) {
        _currentPage = nextPage;
        _sections.addAll(response.sections);
        _hasReachedMax = response.sections.length < _perPage;
        emit(HomeLayoutLoaded(
          message: _message,
          scopeType: _scopeType,
          sections: List.of(_sections),
          hasReachedMax: _hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        emit(current.copyWith(isLoadingMore: false));
      }
    } catch (_) {
      emit(current.copyWith(isLoadingMore: false));
    } finally {
      _isLoadingMore = false;
    }
  }
}
