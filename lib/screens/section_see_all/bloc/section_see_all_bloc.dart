import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/home_page/model/brands_model.dart';
import 'package:hyper_local/screens/home_page/model/category_model.dart';

import '../model/section_items_response.dart';
import '../repo/section_see_all_repo.dart';
import 'section_see_all_event.dart';
import 'section_see_all_state.dart';

/// Drives the "see all" page for one home-layout section
/// (GET /api/home-layout/sections/{id}), paginated by `?page=&per_page=`.
/// Items are parsed into the section's existing model (CategoryData /
/// BrandData) based on [type]. Mirrors HomeLayoutBloc's pagination contract.
class SectionSeeAllBloc extends Bloc<SectionSeeAllEvent, SectionSeeAllState> {
  final SectionSeeAllRepository repository = SectionSeeAllRepository();

  static const int _perPage = 30;

  int _sectionId = 0;
  String _type = '';
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;
  final List<dynamic> _items = [];

  SectionSeeAllBloc() : super(SectionSeeAllInitial()) {
    on<FetchSectionItems>(_onFetch);
    on<FetchMoreSectionItems>(_onFetchMore);
  }

  bool get _hasReachedMax => _currentPage >= _lastPage;

  /// Maps a raw item map onto the right model for [type]. Unknown types keep
  /// the raw map so the caller can decide how to handle them.
  dynamic _parseItem(Map<String, dynamic> json) {
    switch (_type) {
      case 'categories':
        return CategoryData.fromJson(json);
      case 'brands':
        return BrandData.fromJson(json);
      default:
        return json;
    }
  }

  Future<void> _onFetch(
    FetchSectionItems event,
    Emitter<SectionSeeAllState> emit,
  ) async {
    emit(SectionSeeAllLoading());
    _sectionId = event.sectionId;
    _type = event.type;
    _currentPage = 1;
    _lastPage = 1;
    _isLoadingMore = false;
    _items.clear();
    try {
      final raw = await repository.fetchSection(
        sectionId: _sectionId,
        page: _currentPage,
        perPage: _perPage,
      );
      final response = SectionItemsResponse.fromJson(raw);
      if (response.success) {
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _items
          ..clear()
          ..addAll(response.items.map(_parseItem));
        emit(SectionSeeAllLoaded(
          type: _type,
          items: List.of(_items),
          hasReachedMax: _hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        emit(SectionSeeAllFailed(error: response.message));
      }
    } catch (e) {
      emit(SectionSeeAllFailed(error: e.toString()));
    }
  }

  Future<void> _onFetchMore(
    FetchMoreSectionItems event,
    Emitter<SectionSeeAllState> emit,
  ) async {
    if (_hasReachedMax || _isLoadingMore) return;
    final current = state;
    if (current is! SectionSeeAllLoaded) return;

    _isLoadingMore = true;
    emit(current.copyWith(isLoadingMore: true));
    try {
      final nextPage = _currentPage + 1;
      final raw = await repository.fetchSection(
        sectionId: _sectionId,
        page: nextPage,
        perPage: _perPage,
      );
      final response = SectionItemsResponse.fromJson(raw);
      if (response.success) {
        _currentPage = response.currentPage;
        _lastPage = response.lastPage;
        _items.addAll(response.items.map(_parseItem));
        emit(SectionSeeAllLoaded(
          type: _type,
          items: List.of(_items),
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
