import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

import '../model/shared_cart.dart';
import '../service/shared_cart_service.dart';

class SharedCartState extends Equatable {
  final bool loading;
  final bool importing;
  final SharedCartPreview? preview;
  final SharedCartImport? result;
  final String? error;
  final bool needsLocation;
  const SharedCartState(
      {this.loading = false,
      this.importing = false,
      this.preview,
      this.result,
      this.error,
      this.needsLocation = false});

  @override
  List<Object?> get props =>
      [loading, importing, preview, result, error, needsLocation];
}

class SharedCartCubit extends Cubit<SharedCartState> {
  final SharedCartService service;
  final String code;
  SharedCartCubit({required this.service, required this.code})
      : super(const SharedCartState());

  Future<void> load() async {
    if (state.loading || state.importing || state.result != null) return;
    emit(const SharedCartState(loading: true));
    try {
      final preview = await service.preview(code);
      if (!isClosed) emit(SharedCartState(preview: preview));
    } on SharedCartLocationRequired {
      if (!isClosed) emit(const SharedCartState(needsLocation: true));
    } catch (error) {
      if (!isClosed) emit(SharedCartState(error: error.toString()));
    }
  }

  Future<void> importCart(SharedCartAction action) async {
    final preview = state.preview;
    if (preview == null ||
        preview.isExpired ||
        state.importing ||
        state.result != null) {
      return;
    }
    emit(SharedCartState(preview: preview, importing: true));
    try {
      final result = await service.importCart(code, action, preview);
      if (!isClosed) emit(SharedCartState(preview: preview, result: result));
    } on SharedCartImportCommitted catch (error) {
      if (!isClosed) {
        emit(SharedCartState(
            preview: preview, result: error.result, error: error.toString()));
      }
    } catch (error) {
      if (!isClosed) {
        emit(SharedCartState(preview: preview, error: error.toString()));
      }
    }
  }
}
