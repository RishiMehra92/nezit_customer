import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_http_inspector/flutter_http_inspector.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hyper_local/bloc/theme_bloc/theme_bloc.dart';
import 'package:hyper_local/bloc/language_bloc/language_bloc.dart';
import 'package:hyper_local/router/app_routes.dart';
import 'package:hyper_local/widgets/cart_state_listener.dart';
import 'package:animated_theme_switcher/animated_theme_switcher.dart';

import 'screens/support_page/service/support_websocket_connection.dart';
import 'utils/theme_switcher_provider.dart';
import 'app/app_bloc_observer.dart';
import 'app/app_bootstrap.dart';
import 'config/dependency_injection_container.dart';
import 'config/global.dart';
import 'config/global_bloc_providers.dart';
import 'config/theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/share_cart/widgets/shared_cart_coordinator.dart';

void main() async {
  await runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      SupportWebSocketConnection.captureHttpOverridesBeforeInspector();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
      };
      HttpInspector.setup();

      await AppBootstrap.initCore();
      setupLocator();
      Bloc.observer = AppBlocObserver();

      runApp(const MyApp());
    },
    (error, stackTrace) {
      debugPrint('Unhandled app error: $error');
      debugPrintStack(stackTrace: stackTrace);
    },
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: globalBlocProviders(),
      child: const CartStateListener(child: _AnimatedThemeWrapper()),
    );
  }
}

class _AnimatedThemeWrapper extends StatelessWidget {
  const _AnimatedThemeWrapper();

  @override
  Widget build(BuildContext context) {
    final themeMode = context.select((ThemeBloc bloc) => bloc.state);
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final initialTheme = AppTheme.resolveFromMode(themeMode, brightness);

    return ThemeProvider(
      initTheme: initialTheme,
      builder: (context, theme) {
        return ThemeSwitcher.switcher(
          builder: (context, switcher) {
            return ThemeSwitcherProvider(
              changeTheme: (theme) => switcher.changeTheme(theme: theme),
              child: BlocBuilder<ThemeBloc, ThemeMode>(
                builder: (context, themeMode) {
                  return BlocBuilder<LanguageBloc, LanguageState>(
                    builder: (context, languageState) {
                      return GestureDetector(
                        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                        child: ScreenUtilInit(
                          child: SafeArea(
                            top: false,
                            bottom: Platform.isIOS ? false : true,
                            left: false,
                            right: false,
                            child: MaterialApp.router(
                              debugShowCheckedModeBanner: false,
                              theme: theme,
                              darkTheme: AppTheme.darkTheme,
                              themeMode: themeMode,
                              builder: (context, child) {
                                final content = FToastBuilder()(context, child);
                                return Directionality(
                                  textDirection: languageState is LanguageLoaded && languageState.isRtl
                                      ? TextDirection.rtl
                                      : TextDirection.ltr,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      SharedCartCoordinator(child: content),
                                      ValueListenableBuilder<bool>(
                                        valueListenable: Global.httpInspectorEnabledNotifier,
                                        builder: (context, isEnabled, _) {
                                          if (!isEnabled) return const SizedBox.shrink();
                                          return const HttpInspectorOverlay(
                                            enabled: true,
                                            child: SizedBox.shrink(),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                              routerConfig: MyAppRoute.router,
                              localizationsDelegates: const [
                                GlobalMaterialLocalizations.delegate,
                                GlobalWidgetsLocalizations.delegate,
                                GlobalCupertinoLocalizations.delegate,
                              ],
                              supportedLocales: Global.supportedLanguages
                                  .map((l) => Locale(l['code']!))
                                  .toList(),
                              locale: languageState is LanguageLoaded ? languageState.locale : const Locale('en'),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
