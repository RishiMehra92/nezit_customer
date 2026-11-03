import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hyper_local/screens/near_by_stores/repo/near_by_store_repo.dart';

import '../../model/near_by_store_model.dart';

part 'store_detail_event.dart';
part 'store_detail_state.dart';

class StoreDetailBloc extends Bloc<StoreDetailEvent, StoreDetailState> {
  StoreDetailBloc() : super(StoreDetailInitial()) {
    on<FetchStoreDetail>(_onFetchStoreDetail);
    on<UpdateStoreDetailNotification>(_onUpdateStoreDetailNotification);
  }

  final NearByStoreRepo repository = NearByStoreRepo();

  Future<void> _onFetchStoreDetail(
      FetchStoreDetail event, Emitter<StoreDetailState> emit) async {
    emit(StoreDetailLoading());
    try {
      final storeData = await repository.fetchStoreDetail(
        storeSlug: event.storeSlug,
        isNotify: event.isNotify,
      );

      if (storeData.isNotEmpty && storeData.first.success == true) {
        if (storeData.first.data?.name != null) {
          emit(StoreDetailLoaded(storeData: storeData.first.data!));
        } else {
          emit(StoreDetailFailed(error: storeData.first.message ?? ''));
        }
      } else {
        emit(StoreDetailFailed(error: storeData.first.message ?? ''));
      }
    } catch (e) {
      emit(StoreDetailFailed(error: e.toString()));
    }
  }

  void _onUpdateStoreDetailNotification(
      UpdateStoreDetailNotification event, Emitter<StoreDetailState> emit) {
    final currentState = state;
    if (currentState is StoreDetailLoaded) {
      emit(StoreDetailLoaded(
        storeData: currentState.storeData.copyWith(isNotify: event.isNotify),
      ));
    }
  }
}
