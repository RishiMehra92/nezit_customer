import 'dart:io';
import 'package:fast_cached_network_image/fast_cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hyper_local/config/global.dart';
import 'package:hyper_local/firebase_options.dart';
import 'package:hyper_local/model/recent_product_model/recent_product_model.dart';
import 'package:hyper_local/model/user_cart_model/cart_addon.dart';
import 'package:hyper_local/model/user_cart_model/cart_sync_action.dart';
import 'package:hyper_local/model/user_cart_model/user_cart.dart';
import 'package:hyper_local/repo/language_repo.dart';
import 'package:hyper_local/services/address/selected_address_hive.dart';
import 'package:hyper_local/services/location/user_location_hive.dart';
import 'package:hyper_local/services/shopping_list_hive.dart';

class AppBootstrap {
  static Future<void> initCore() async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }
    } catch (e) {
      if (!e.toString().contains('duplicate-app')) {
        rethrow;
      }
    }
    
    await Hive.initFlutter();
    Hive.registerAdapter(CartSyncActionAdapter());
    Hive.registerAdapter(CartAddonAdapter());
    Hive.registerAdapter(UserCartAdapter());
    Hive.registerAdapter(RecentProductAdapter());

    await Hive.openBox<UserCart>('cartBox');
    await Hive.openBox('themebox');

    await Global.initialize();
    await Global.initializePrefs();
    await LanguageRepo.initCache();

    try {
      await HiveLocationHelper.init();
    } catch (e) {
      debugPrint('HiveLocationHelper.init error: $e');
    }

    try {
      await HiveSelectedAddressHelper.init();
    } catch (e) {
      debugPrint('HiveSelectedAddressHelper.init error: $e');
    }

    try {
      await ShoppingListHiveHelper.init();
    } catch (e) {
      debugPrint('ShoppingListHiveHelper.init error: $e');
    }

    if (kDebugMode) {
      HttpClient.enableTimelineLogging = true;
    }
  }

  static Future<void> initHeavy() async {
    try {
      await FastCachedImageConfig.init();
    } catch (e) {
      debugPrint('FastCachedImageConfig.init error: $e');
    }

    try {
      if (!Hive.isBoxOpen(HiveLocationHelper.boxName)) {
        await HiveLocationHelper.init();
      }
    } catch (e) {
      debugPrint('HiveLocationHelper.init error: $e');
    }

    try {
      if (!Hive.isBoxOpen(HiveSelectedAddressHelper.boxName)) {
        await HiveSelectedAddressHelper.init();
      }
    } catch (e) {
      debugPrint('HiveSelectedAddressHelper.init error: $e');
    }

    try {
      await ShoppingListHiveHelper.init();
    } catch (e) {
      debugPrint('ShoppingListHiveHelper.init error: $e');
    }
  }
}
