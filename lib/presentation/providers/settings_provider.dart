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

  const SettingsState({this.fontFamily = 'NotoSansTC'});

  SettingsState copyWith({String? fontFamily}) {
    return SettingsState(
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  static const _fontKey = 'selectedFontFamily';

  @override
  SettingsState build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedFont = prefs.getString(_fontKey) ?? 'NotoSansTC';
    return SettingsState(fontFamily: savedFont);
  }

  Future<void> updateFontFamily(String newFontFamily) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_fontKey, newFontFamily);
    state = state.copyWith(fontFamily: newFontFamily);
  }
}
