import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Provide the SharedPreferences instance synchronously
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});

class SettingsState {
  final String fontFamily;
  final String locale;
  final String dateFormat;
  final String themeMode;
  final String? lastSyncTime;

  const SettingsState({
    this.fontFamily = 'NotoSansTC',
    this.locale = 'en',
    this.dateFormat = 'yyyy/MM/dd',
    this.themeMode = 'system',
    this.lastSyncTime,
  });

  SettingsState copyWith({String? fontFamily, String? locale, String? dateFormat, String? themeMode, String? lastSyncTime}) {
    return SettingsState(
      fontFamily: fontFamily ?? this.fontFamily,
      locale: locale ?? this.locale,
      dateFormat: dateFormat ?? this.dateFormat,
      themeMode: themeMode ?? this.themeMode,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _fontKey = 'selectedFontFamily';
  static const _localeKey = 'selectedLocale';
  static const _dateFormatKey = 'selectedDateFormat';
  static const _themeModeKey = 'selectedThemeMode';
  static const _lastSyncTimeKey = 'lastSyncTime';

  String _getDefaultFont(String locale) {
    return locale == 'zh_CN' ? 'NotoSansSC' : 'NotoSansTC';
  }

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    
    // Auto detect locale if not saved
    String savedLocale = prefs.getString(_localeKey) ?? '';
    if (savedLocale.isEmpty) {
      final platformLocale = PlatformDispatcher.instance.locale;
      if (platformLocale.languageCode == 'zh') {
        if (platformLocale.countryCode == 'TW' || platformLocale.countryCode == 'HK' || platformLocale.countryCode == 'MO') {
          savedLocale = 'zh_TW';
        } else {
          savedLocale = 'zh_CN';
        }
      } else {
        savedLocale = 'en';
      }
    }

    final savedFont = prefs.getString(_fontKey);
    final bool isUsingDefaultFont = savedFont == null || savedFont == 'NotoSansTC' || savedFont == 'NotoSansSC';

    final savedDateFormat = prefs.getString(_dateFormatKey) ?? 'yyyy/MM/dd';
    final savedThemeMode = prefs.getString(_themeModeKey) ?? 'system';
    final lastSyncTime = prefs.getString(_lastSyncTimeKey);

    return SettingsState(
      fontFamily: isUsingDefaultFont ? _getDefaultFont(savedLocale) : savedFont,
      locale: savedLocale,
      dateFormat: savedDateFormat,
      themeMode: savedThemeMode,
      lastSyncTime: lastSyncTime,
    );
  }

  Future<void> clearFontFamily() async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.remove(_fontKey);
    state = state.copyWith(fontFamily: _getDefaultFont(state.locale));
  }

  Future<void> updateFontFamily(String newFontFamily) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_fontKey, newFontFamily);
    state = state.copyWith(fontFamily: newFontFamily);
  }

  Future<void> updateLocale(String newLocale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, newLocale);
    
    final savedFont = prefs.getString(_fontKey);
    final bool isUsingDefaultFont = savedFont == null || savedFont == 'NotoSansTC' || savedFont == 'NotoSansSC';

    state = state.copyWith(
      locale: newLocale,
      fontFamily: isUsingDefaultFont ? _getDefaultFont(newLocale) : savedFont,
    );
  }

  Future<void> updateDateFormat(String newFormat) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_dateFormatKey, newFormat);
    state = state.copyWith(dateFormat: newFormat);
  }

  Future<void> updateThemeMode(String newMode) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeModeKey, newMode);
    state = state.copyWith(themeMode: newMode);
  }

  Future<void> updateLastSyncTime(String time) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_lastSyncTimeKey, time);
    state = state.copyWith(lastSyncTime: time);
  }
}
