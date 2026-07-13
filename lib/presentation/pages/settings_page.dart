import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/settings_provider.dart';
import '../../core/utils/system_fonts.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  List<String> _systemFonts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFonts();
  }

  Future<void> _loadFonts() async {
    final fonts = await SystemFontsHelper.getSystemFonts();
    
    // Ensure NotoSansTC is always the first option (as default)
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

  void _showFontSelectionDialog(BuildContext context, String currentFont) {
    showDialog(
      context: context,
      builder: (context) {
        return _FontSelectionDialog(
          systemFonts: _systemFonts,
          currentFont: currentFont,
          onSelected: (font) {
            ref.read(settingsProvider.notifier).updateFontFamily(font);
            Navigator.of(context).pop();
          },
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
          '設置',
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
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              Text(
                '外觀與顯示',
                style: ShadTheme.of(context).textTheme.large,
              ),
              const SizedBox(height: 16),
              ShadCard(
                padding: const EdgeInsets.all(0),
                child: ListTile(
                  title: const Text('應用程式字體'),
                  subtitle: Text(
                    settings.fontFamily == 'NotoSansTC' ? '思源黑體 (預設)' : settings.fontFamily,
                  ),
                  trailing: const Icon(LucideIcons.chevronRight),
                  onTap: () {
                    _showFontSelectionDialog(context, settings.fontFamily);
                  },
                ),
              ),
            ],
          ),
    );
  }
}

class _FontSelectionDialog extends StatefulWidget {
  final List<String> systemFonts;
  final String currentFont;
  final ValueChanged<String> onSelected;

  const _FontSelectionDialog({
    required this.systemFonts,
    required this.currentFont,
    required this.onSelected,
  });

  @override
  State<_FontSelectionDialog> createState() => _FontSelectionDialogState();
}

class _FontSelectionDialogState extends State<_FontSelectionDialog> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final filteredFonts = widget.systemFonts
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
              '選擇字體',
              style: ShadTheme.of(context).textTheme.h4,
            ),
            const SizedBox(height: 16),
            ShadInput(
              placeholder: const Text('搜尋字體...'),
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
                      isDefault ? '思源黑體 (預設)' : font,
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
        ),
      ),
    );
  }
}
