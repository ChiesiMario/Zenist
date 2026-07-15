import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../providers/settings_provider.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/system_fonts.dart';
import '../../core/localization/translations.dart';
import '../../application/services/auto_sync_manager.dart';
import '../../core/utils/toast_utils.dart';

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
          onSelected: (font, isDefault) {
            if (isDefault) {
              ref.read(settingsProvider.notifier).clearFontFamily();
            } else {
              ref.read(settingsProvider.notifier).updateFontFamily(font);
            }
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
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
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
                  title: Text(Translations.tr('lang_zh_tw', currentLocale)),
                  trailing: currentLocale == 'zh_TW' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLocale('zh_TW');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text(Translations.tr('lang_zh_cn', currentLocale)),
                  trailing: currentLocale == 'zh_CN' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLocale('zh_CN');
                    Navigator.of(context).pop();
                  },
                ),
                ListTile(
                  title: Text(Translations.tr('lang_en', currentLocale)),
                  trailing: currentLocale == 'en' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).updateLocale('en');
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  void _showDateFormatSelectionDialog(BuildContext context, String currentFormat, String locale) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 350),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Translations.tr('date_format', locale),
                    style: ShadTheme.of(context).textTheme.h4,
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    title: Text(Translations.tr('format_ymd', locale)),
                    trailing: currentFormat == 'yyyy/MM/dd' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).updateDateFormat('yyyy/MM/dd');
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: Text(Translations.tr('format_mdy', locale)),
                    trailing: currentFormat == 'MM/dd/yyyy' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).updateDateFormat('MM/dd/yyyy');
                      Navigator.of(context).pop();
                    },
                  ),
                  ListTile(
                    title: Text(Translations.tr('format_dmy', locale)),
                    trailing: currentFormat == 'dd/MM/yyyy' ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                    onTap: () {
                      ref.read(settingsProvider.notifier).updateDateFormat('dd/MM/yyyy');
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final locale = settings.locale;

    return Scaffold(
      backgroundColor: ShadTheme.of(context).colorScheme.background,
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // Main Content
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 70.0, bottom: 24.0),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // 第一張卡片：外觀與顯示
                        Container(
                          decoration: BoxDecoration(
                            color: ShadTheme.of(context).colorScheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ShadTheme.of(context).colorScheme.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 24,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                                child: Text(
                                  Translations.tr('appearance_and_display', locale),
                                  style: ShadTheme.of(context).textTheme.large,
                                ),
                              ),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                leading: const Icon(LucideIcons.globe, size: 20),
                                title: Text(Translations.tr('language', locale), 
                                  style: ShadTheme.of(context).textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.normal)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    locale == 'zh_TW' ? Translations.tr('lang_zh_tw', locale) :
                                    locale == 'zh_CN' ? Translations.tr('lang_zh_cn', locale) : 
                                    Translations.tr('lang_en', locale),
                                    style: ShadTheme.of(context).textTheme.small.copyWith(
                                      fontSize: 12,
                                      color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 20),
                                onTap: () {
                                  _showLanguageSelectionDialog(context, locale);
                                },
                              ),
                              Divider(height: 1, color: ShadTheme.of(context).colorScheme.border.withOpacity(0.5)),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                leading: const Icon(LucideIcons.calendar, size: 20),
                                title: Text(Translations.tr('date_format', locale),
                                  style: ShadTheme.of(context).textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.normal)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    settings.dateFormat == 'yyyy/MM/dd' ? Translations.tr('format_ymd', locale) :
                                    settings.dateFormat == 'MM/dd/yyyy' ? Translations.tr('format_mdy', locale) : 
                                    Translations.tr('format_dmy', locale),
                                    style: ShadTheme.of(context).textTheme.small.copyWith(
                                      fontSize: 12,
                                      color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 20),
                                onTap: () {
                                  _showDateFormatSelectionDialog(context, settings.dateFormat, locale);
                                },
                              ),
                              Divider(height: 1, color: ShadTheme.of(context).colorScheme.border.withOpacity(0.5)),
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                                leading: const Icon(LucideIcons.type, size: 20),
                                title: Text(Translations.tr('app_font', locale),
                                  style: ShadTheme.of(context).textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.normal)),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Text(
                                    (settings.fontFamily == 'NotoSansTC' || settings.fontFamily == 'NotoSansSC') 
                                        ? Translations.tr('default_font', locale) 
                                        : settings.fontFamily,
                                    style: ShadTheme.of(context).textTheme.small.copyWith(
                                      fontSize: 12,
                                      color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5),
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                ),
                                trailing: const Icon(LucideIcons.chevronRight, size: 20),
                                onTap: () {
                                  _showFontSelectionDialog(context, settings.fontFamily, locale);
                                },
                              ),
                              const SizedBox(height: 8), // 底部留白
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        // 第二張卡片：雲端同步
                        Container(
                          decoration: BoxDecoration(
                            color: ShadTheme.of(context).colorScheme.card,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: ShadTheme.of(context).colorScheme.border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 24,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
                                child: Text(
                                  Translations.tr('cloud_sync', locale),
                                  style: ShadTheme.of(context).textTheme.large,
                                ),
                              ),
                              _SyncSection(locale: locale),
                              const SizedBox(height: 8), // 底部留白
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Header
          SafeArea(
            bottom: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                child: SizedBox(
                  height: 60.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ShadButton.ghost(
                          onPressed: () => Navigator.of(context).pop(),
                          width: 48,
                          height: 48,
                          padding: EdgeInsets.zero,
                          child: const Icon(LucideIcons.arrowLeft, size: 24),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Translations.tr('settings', locale),
                          style: ShadTheme.of(context).textTheme.h2.copyWith(
                                fontFamily: 'Nunito',
                                fontWeight: FontWeight.w800,
                                fontSize: 24,
                                letterSpacing: -0.5,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }
}

class _FontSelectionDialog extends StatefulWidget {
  final String currentFont;
  final String locale;
  final void Function(String, bool) onSelected;

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
    if (fonts.contains('NotoSansSC')) {
      fonts.remove('NotoSansSC');
    }
    
    final defaultFont = widget.locale == 'zh_CN' ? 'NotoSansSC' : 'NotoSansTC';
    fonts.insert(0, defaultFont);

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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 350),
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
                    final defaultFont = widget.locale == 'zh_CN' ? 'NotoSansSC' : 'NotoSansTC';
                    final isDefault = font == defaultFont;
                    
                    return ListTile(
                      title: Text(
                        isDefault ? Translations.tr('default_font', widget.locale) : font,
                        style: TextStyle(
                          fontFamily: font,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected ? const Icon(LucideIcons.check, color: Colors.blue) : null,
                      onTap: () => widget.onSelected(font, isDefault),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
        ),
      ),
    );
  }
}

class _SyncSection extends ConsumerStatefulWidget {
  final String locale;
  const _SyncSection({required this.locale});

  @override
  ConsumerState<_SyncSection> createState() => _SyncSectionState();
}

class _SyncSectionState extends ConsumerState<_SyncSection> {
  bool _isSyncing = false;

  Future<void> _handleLogin() async {
    try {
      await ref.read(authProvider.notifier).login();
      if (ref.read(authProvider).isLoggedIn) {
        await _handleSync();
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Login failed: $e');
      }
    }
  }

  Future<void> _handleLogout() async {
    await ref.read(authProvider.notifier).logout();
  }

  Future<void> _handleSync() async {
    final authState = ref.read(authProvider);
    if (!authState.isLoggedIn) return;
    
    final syncManager = ref.read(autoSyncManagerProvider.notifier);
    // Since autoSyncManager handles its own state, we don't need local _isSyncing, 
    // but the UI currently uses it to disable the button.
    // We can just call it and it will block if already syncing.
    setState(() => _isSyncing = true);
    try {
      await syncManager.manualSync();
      if (mounted) {
        ToastUtils.show(context, 'Sync completed successfully');
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(context, 'Sync failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoggedIn = authState.isLoggedIn;
    final lastSyncTime = ref.watch(settingsProvider).lastSyncTime;

    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          leading: const Icon(LucideIcons.cloud, size: 20),
          title: Text(isLoggedIn ? Translations.tr('dropbox_unlink', widget.locale) : Translations.tr('dropbox_link', widget.locale),
            style: ShadTheme.of(context).textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.normal)),
          subtitle: (isLoggedIn && authState.email != null) 
              ? Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(authState.email!,
                    style: ShadTheme.of(context).textTheme.small.copyWith(
                      fontSize: 12,
                      color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5),
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                )
              : null,
          onTap: isLoggedIn ? _handleLogout : _handleLogin,
        ),
        if (isLoggedIn)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            leading: _isSyncing 
                ? const SizedBox(width: 19, height: 19, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.refreshCw, size: 19),
            title: Text(Translations.tr('sync_now', widget.locale),
              style: ShadTheme.of(context).textTheme.p.copyWith(fontSize: 15, fontWeight: FontWeight.normal)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                lastSyncTime != null 
                    ? '${Translations.tr('last_synced', widget.locale)} $lastSyncTime'
                    : '尚未同步 (Never synced)',
                style: ShadTheme.of(context).textTheme.small.copyWith(
                  fontSize: 12,
                  color: ShadTheme.of(context).colorScheme.mutedForeground.withValues(alpha: 0.5),
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
            onTap: _isSyncing ? null : _handleSync,
          ),
      ],
    );
  }
}
