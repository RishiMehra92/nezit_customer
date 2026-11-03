import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Holds a referral code captured from a deep link (or pre-auth input) so it
/// can be applied automatically once the user completes social sign-in.
///
/// Backed by the same Hive `AppPrefsBox` already used for simple app flags.
/// Read/written only via this service — widgets and blocs must never touch
/// the box directly.
class ReferralAttributionService {
  static const String _boxName = 'AppPrefsBox';
  static const String _codeKey = 'pendingReferralCode';
  static const String _promptShownKey = 'referralPromptShown';

  /// In-memory flag that lives only for the current app session.
  /// Set to `true` when a user completes registration; consumed by the
  /// home page to show the referral prompt once.  Because it is in-memory,
  /// it is automatically `false` on cold start — the prompt will never
  /// re-appear after an app restart.
  static bool _justRegistered = false;

  Future<Box> _box() => Hive.openBox(_boxName);

  Future<void> setCode(String code) async {
    if (code.isEmpty) return;
    try {
      final box = await _box();
      await box.put(_codeKey, code);
    } catch (e) {
      debugPrint('ReferralAttributionService.setCode failed: $e');
    }
  }

  Future<String?> getCode() async {
    try {
      final box = await _box();
      return box.get(_codeKey) as String?;
    } catch (e) {
      debugPrint('ReferralAttributionService.getCode failed: $e');
      return null;
    }
  }

  Future<void> clearCode() async {
    try {
      final box = await _box();
      await box.delete(_codeKey);
    } catch (e) {
      debugPrint('ReferralAttributionService.clearCode failed: $e');
    }
  }

  /// Mark the user as just-registered for this session only.
  /// This is intentionally **not** persisted to Hive so it cannot survive
  /// an app restart.
  Future<void> setJustRegistered(bool value) async {
    _justRegistered = value;
  }

  /// Returns `true` only if [setJustRegistered(true)] was called during
  /// this app session.
  Future<bool> getJustRegistered() async {
    return _justRegistered;
  }

  Future<void> setPromptShown(bool value) async {
    try {
      final box = await _box();
      await box.put(_promptShownKey, value);
    } catch (e) {
      debugPrint('ReferralAttributionService.setPromptShown failed: $e');
    }
  }

  Future<bool> getPromptShown() async {
    try {
      final box = await _box();
      return box.get(_promptShownKey, defaultValue: false) as bool;
    } catch (e) {
      debugPrint('ReferralAttributionService.getPromptShown failed: $e');
      return false;
    }
  }
}
