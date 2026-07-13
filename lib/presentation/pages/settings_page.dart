import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/settings_provider.dart';
import '../../core/utils/system_fonts.dart';
import '../../core/localization/translations.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  void _showFontSelectionDialog(BuildContext context, String currentFont, String locale) {
    showDialog(
      context: context,
      builder: (context) {
        return _FontSelectionDialog(
          currentFont: currentFont,
          locale: locale,
          onSelected: (font) {
            ref.read(settingsProvider.notifier).updateFontFamily(font);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _showLanguageSelectionDialog(BuildContext context, String currentLocale) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Translations.tr('select_language', currentLocale),
                  style: ShadTheme.of(context).textTheme.h4,
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('繁體中文'),
                  trailing: currentLocale == 'zh_TW' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLocale('zh_TW');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('简体中文'),
                  trailing: currentLocale == 'zh_CN' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLocale('zh_CN');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: const Text('English'),
                  trailing: currentLocale == 'en' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLocale('en');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: ShadTheme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          Translations.tr('settings', settings.locale),
          style: ShadTheme.of(context).textTheme.h4,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: ShadButton.ghost(
          child: const Icon(LucideIcons.arrowLeft, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        iconTheme: IconThemeData(
          color: ShadTheme.of(context).colorScheme.foreground,
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                Translations.tr('appearance_and_display', settings.locale),
                style: ShadTheme.of(context).textTheme.large,
              ),
              const SizedBox(height: 16),
              ShadCard(
                padding: const EdgeInsets.all(0),
                child: Column(
                  children: [
                    ListTile(
                      title: Text(Translations.tr('language', settings.locale)),
                      subtitle: Text(
                        settings.locale == 'zh_TW' ? '繁體中文' :
                        settings.locale == 'zh_CN' ? '简体中文' : 'English',
                      ),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () {
                        _showLanguageSelectionDialog(context, settings.locale);
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      title: Text(Translations.tr('app_font', settings.locale)),
                      subtitle: Text(
                        settings.fontFamily == 'NotoSansTC' ? Translations.tr('default_font', settings.locale) : settings.fontFamily,
                      ),
                      trailing: const Icon(LucideIcons.chevronRight),
                      onTap: () {
                        _showFontSelectionDialog(context, settings.fontFamily, settings.locale);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FontSelectionDialog extends StatefulWidget {
  final String currentFont;
  final String locale;
  final ValueChanged<String> onSelected;

  const _FontSelectionDialog({
    required this.currentFont,
    required this.locale,
    required this.onSelected,
  });

  @override
  State<_FontSelectionDialog> createState() => _FontSelectionDialogState();
}

class _FontSelectionDialogState extends State<_FontSelectionDialog> {
  String _searchQuery = '';
  List<String> _systemFonts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final fonts = await SystemFontsHelper.getSystemFonts();
    
    if (fonts.contains('NotoSansTC')) {
      fonts.remove('NotoSansTC');
    }
    fonts.insert(0, 'NotoSansTC');

    if (mounted) {
      setState(() {
        _systemFonts = fonts;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredFonts = _systemFonts
        .where((font) => font.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.6,
        child: Column(
          children: [
            Text(
              Translations.tr('select_font', widget.locale),
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              ShadInput(
                placeholder: Text(Translations.tr('search_font', widget.locale)),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: filteredFonts.length,
                  itemBuilder: (context, index) {
                    final font = filteredFonts[index];
                    final isSelected = font == widget.currentFont;
                    final isDefault = font == 'NotoSansTC';
                    
                    return ListTile(
                      title: Text(
                        isDefault ? Translations.tr('default_font', widget.locale) : font,
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                      onTap: () => widget.onSelected(font),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
