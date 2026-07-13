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

  const SettingsState({
    this.fontFamily = 'NotoSansTC',
    this.locale = 'en',
    this.dateFormat = 'yyyy/MM/dd',
  });

  SettingsState copyWith({String? fontFamily, String? locale, String? dateFormat}) {
    return SettingsState(
      fontFamily: fontFamily ?? this.fontFamily,
      locale: locale ?? this.locale,
      dateFormat: dateFormat ?? this.dateFormat,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _fontKey = 'selectedFontFamily';
  static const _localeKey = 'selectedLocale';
  static const _dateFormatKey = 'selectedDateFormat';

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

    return SettingsState(
      fontFamily: isUsingDefaultFont ? _getDefaultFont(savedLocale) : savedFont,
      locale: savedLocale,
      dateFormat: savedDateFormat,
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
}
