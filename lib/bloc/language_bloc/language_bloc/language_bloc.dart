import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:get_it/get_it.dart';
import '../../../config/global.dart';
import '../../../model/language_model/language_model.dart';
import '../../../repo/language_repo.dart';
import '../language_list_bloc/language_list_bloc.dart';
import '../../../screens/home_page/home_layout/bloc/home_layout_bloc.dart';
import '../../../screens/home_page/home_layout/bloc/home_layout_event.dart';
import '../../../screens/home_page/home_layout/bloc/home_layout_state.dart';
import '../../../screens/home_page/bloc/category/category_bloc.dart';
import '../../../screens/home_page/bloc/category/category_event.dart';
import '../../../screens/home_page/bloc/category/category_state.dart';
import '../../../screens/cart_page/bloc/get_user_cart/get_user_cart_bloc.dart';
import '../../../screens/wishlist_page/bloc/get_user_wishlist_bloc/get_user_wishlist_bloc.dart';

part 'language_event.dart';
part 'language_state.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  final LanguageRepo languageRepo;

  LanguageBloc({LanguageRepo? languageRepo})
      : languageRepo = languageRepo ?? LanguageRepo(),
        super(_resolveInitialState(languageRepo ?? LanguageRepo())) {
    on<LoadLanguage>(_onLoadLanguage);
    on<FetchLanguages>(_onFetchLanguages);
    on<ChangeLanguage>(_onChangeLanguage);
  }

  static LanguageState _resolveInitialState(LanguageRepo repo) {
    final activeCode = Global.currentLanguage;
    final cached = LanguageRepo.getCachedLanguagesSync();
    final matchingLang = cached?.data?.languages?.firstWhere(
      (l) => l.code == activeCode,
      orElse: () => LanguageData(code: activeCode, direction: 'ltr'),
    );
    final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

    return LanguageLoaded(
      languageModel: cached ?? LanguageModel(),
      defaultLanguage: cached?.data?.defaultLanguage ?? 'en',
      currentLanguage: activeCode,
      locale: Locale(activeCode),
      isRtl: isRtl,
    );
  }

  Future<void> _onLoadLanguage(
      LoadLanguage event, Emitter<LanguageState> emit) async {
    final savedLang = await Global.getPersistedLanguage();

    // 1. Emit cached languages immediately if available for 0ms startup
    final cached = LanguageRepo.getCachedLanguagesSync() ?? await languageRepo.getCachedLanguages();
    if (cached != null && cached.data != null) {
      final activeCode =
          (savedLang.isNotEmpty) ? savedLang : (cached.data?.defaultLanguage ?? 'en');
      final matchingLang = cached.data?.languages?.firstWhere(
        (l) => l.code == activeCode,
        orElse: () => LanguageData(code: activeCode, direction: 'ltr'),
      );
      final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

      emit(LanguageLoaded(
        languageModel: cached,
        defaultLanguage: cached.data!.defaultLanguage ?? 'en',
        currentLanguage: activeCode,
        locale: Locale(activeCode),
        isRtl: isRtl,
      ));
    } else if (state is! LanguageLoaded) {
      emit(LanguageLoading());
    }

    // 2. Fetch fresh languages from API
    try {
      final data = await languageRepo.fetchLanguages();
      if (data.success == true && data.data != null) {
        final activeCode =
            (savedLang.isNotEmpty) ? savedLang : (data.data?.defaultLanguage ?? 'en');
        final matchingLang = data.data?.languages?.firstWhere(
          (l) => l.code == activeCode,
          orElse: () => LanguageData(code: activeCode, direction: 'ltr'),
        );
        final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

        emit(LanguageLoaded(
          languageModel: data,
          defaultLanguage: data.data!.defaultLanguage ?? 'en',
          currentLanguage: activeCode,
          locale: Locale(activeCode),
          isRtl: isRtl,
        ));
      } else if (state is! LanguageLoaded) {
        emit(LanguageError(message: data.message ?? 'Failed to load languages'));
      }
    } catch (e) {
      if (state is! LanguageLoaded) {
        emit(LanguageError(message: e.toString()));
      }
    }
  }

  Future<void> _onFetchLanguages(
      FetchLanguages event, Emitter<LanguageState> emit) async {
    add(const LoadLanguage());
  }

  Future<void> _onChangeLanguage(
      ChangeLanguage event, Emitter<LanguageState> emit) async {
    try {
      await Global.setLanguage(event.languageCode);
      LanguageRepo.loadActiveLabelsSync(event.languageCode);

      // Notify LanguageListBloc to switch labels simultaneously
      try {
        if (GetIt.instance.isRegistered<LanguageListBloc>()) {
          GetIt.instance<LanguageListBloc>().add(FetchLanguageList(locale: event.languageCode));
        }
      } catch (_) {}

      // Refresh catalog Blocs to fetch translated catalog data
      try {
        if (GetIt.instance.isRegistered<HomeLayoutBloc>()) {
          final homeBloc = GetIt.instance<HomeLayoutBloc>();
          if (homeBloc.state is HomeLayoutLoaded) {
            homeBloc.add(const FetchHomeLayout(isRefresh: true));
          }
        }
        if (GetIt.instance.isRegistered<CategoryBloc>()) {
          final catBloc = GetIt.instance<CategoryBloc>();
          if (catBloc.state is CategoryLoaded) {
            catBloc.add(FetchCategory());
          }
        }
        if (GetIt.instance.isRegistered<GetUserCartBloc>()) {
          GetIt.instance<GetUserCartBloc>().add(FetchUserCart());
        }
        if (GetIt.instance.isRegistered<UserWishlistBloc>()) {
          GetIt.instance<UserWishlistBloc>().add(GetUserWishlistRequest());
        }
      } catch (e) {
        debugPrint('Error refreshing catalog on language change: $e');
      }

      final currentModel =
          state is LanguageLoaded ? (state as LanguageLoaded).languageModel : null;

      if (currentModel != null) {
        final matchingLang = currentModel.data?.languages?.firstWhere(
          (l) => l.code == event.languageCode,
          orElse: () => LanguageData(code: event.languageCode, direction: 'ltr'),
        );
        final isRtl = matchingLang?.direction?.toLowerCase() == 'rtl';

        emit(LanguageLoaded(
          languageModel: currentModel,
          defaultLanguage: currentModel.data?.defaultLanguage ?? 'en',
          currentLanguage: event.languageCode,
          locale: Locale(event.languageCode),
          isRtl: isRtl,
        ));
      } else {
        add(const LoadLanguage());
      }
    } catch (e) {
      emit(LanguageError(message: e.toString()));
    }
  }
}

