import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_event.dart';
import 'package:hyper_local/screens/product_detail_page/bloc/product_detail_bloc/product_detail_state.dart';
import 'package:hyper_local/screens/product_detail_page/model/product_detail_model.dart';
import 'package:hyper_local/screens/product_detail_page/repo/product_detail_repo.dart';


class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  ProductDetailBloc() : super(ProductDetailInitial()) {
    on<FetchProductDetail>(_onFetchProductDetail);
    on<ClearProductDetailError>(_onClearProductDetailError);
  }

  final ProductDetailRepository repository = ProductDetailRepository();

  Future<void> _onFetchProductDetail(FetchProductDetail event, Emitter<ProductDetailState> emit) async {
    final currentState = state;
    final isNotifyCall = event.isNotify != null;

    if (isNotifyCall && currentState is ProductDetailLoaded) {
      emit(currentState.copyWith(isNotifying: true, clearError: true));
    } else {
      emit(ProductDetailLoading());
    }

    try {
      final response = await repository.fetchProductDetail(
        productSlug: event.productSlug,
        isNotify: event.isNotify,
        variantId: event.variantId,
      );

      final productDetailModel = ProductDetailModel.fromJson(response);

      if (productDetailModel.success == true && productDetailModel.data != null) {
        emit(ProductDetailLoaded(
          message: productDetailModel.message,
          productData: [productDetailModel.data!],
          isNotifying: false,
        ));
      } else {
        if (isNotifyCall && state is ProductDetailLoaded) {
          emit((state as ProductDetailLoaded).copyWith(
            isNotifying: false,
            errorMessage: productDetailModel.message,
          ));
        } else {
          emit(ProductDetailFailed(error: productDetailModel.message));
        }
      }
    } catch (e) {
      if (isNotifyCall && state is ProductDetailLoaded) {
        emit((state as ProductDetailLoaded).copyWith(
          isNotifying: false,
          errorMessage: e.toString(),
        ));
      } else {
        emit(ProductDetailFailed(error: e.toString()));
      }
    }
  }

  void _onClearProductDetailError(ClearProductDetailError event, Emitter<ProductDetailState> emit) {
    final currentState = state;
    if (currentState is ProductDetailLoaded) {
      emit(currentState.copyWith(clearError: true));
    }
  }
}