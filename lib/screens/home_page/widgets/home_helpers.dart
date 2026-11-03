import '../../../model/settings_model/settings_model.dart';

bool isValidHomeGeneralSettings(HomeGeneralSettings settings) {
  return settings.title.trim().isNotEmpty || settings.icon.trim().isNotEmpty || settings.activeIcon.trim().isNotEmpty;
}
