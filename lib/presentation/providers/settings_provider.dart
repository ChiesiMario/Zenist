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

  const SettingsState({
    this.fontFamily = 'NotoSansTC',
    this.locale = 'en',
  });

  SettingsState copyWith({String? fontFamily, String? locale}) {
    return SettingsState(
      fontFamily: fontFamily ?? this.fontFamily,
      locale: locale ?? this.locale,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _fontKey = 'selectedFontFamily';
  static const _localeKey = 'selectedLocale';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedFont = prefs.getString(_fontKey) ?? 'NotoSansTC';
    
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

    return SettingsState(
      fontFamily: savedFont,
      locale: savedLocale,
    );
  }

  Future<void> updateFontFamily(String newFontFamily) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_fontKey, newFontFamily);
    state = state.copyWith(fontFamily: newFontFamily);
  }

  Future<void> updateLocale(String newLocale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_localeKey, newLocale);
    state = state.copyWith(locale: newLocale);
  }
}
