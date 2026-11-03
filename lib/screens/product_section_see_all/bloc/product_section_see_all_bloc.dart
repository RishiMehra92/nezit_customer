import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart'
    show ProductData;

import '../../section_see_all/model/section_items_response.dart';
import '../../section_see_all/repo/section_see_all_repo.dart';
import 'product_section_see_all_event.dart';
import 'product_section_see_all_state.dart';

class ProductSectionSeeAllBloc
    extends Bloc<ProductSectionSeeAllEvent, ProductSectionSeeAllState> {
  final SectionSeeAllRepository repository = SectionSeeAllRepository();

  static const int _perPage = 12;

  int _sectionId = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  bool _isLoadingMore = false;
  final List<ProductData> _items = [];

  ProductSectionSeeAllBloc() : super(ProductSectionSeeAllInitial()) {
    on<FetchProductSectionItems>(_onFetch);
    on<FetchMoreProductSectionItems>(_onFetchMore);
  }

  bool get _hasReachedMax => _currentPage >= _lastPage;

  Future<void> _onFetch(
    FetchProductSectionItems event,
    Emitter<ProductSectionSeeAllState> emit,
  ) async {
    emit(ProductSectionSeeAllLoading());
    _sectionId = event.sectionId;
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
          ..addAll(response.items.map(ProductData.fromJson));
        emit(ProductSectionSeeAllLoaded(
          items: List.of(_items),
          hasReachedMax: _hasReachedMax,
          isLoadingMore: false,
        ));
      } else {
        emit(ProductSectionSeeAllFailed(error: response.message));
      }
    } catch (e) {
      emit(ProductSectionSeeAllFailed(error: e.toString()));
    }
  }

  Future<void> _onFetchMore(
    FetchMoreProductSectionItems event,
    Emitter<ProductSectionSeeAllState> emit,
  ) async {
    if (_hasReachedMax || _isLoadingMore) return;
    final current = state;
    if (current is! ProductSectionSeeAllLoaded) return;

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
        _items.addAll(response.items.map(ProductData.fromJson));
        emit(ProductSectionSeeAllLoaded(
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
