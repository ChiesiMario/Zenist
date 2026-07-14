import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import 'sync_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/settings_provider.dart';

enum SyncState { idle, manual, auto }

final autoSyncManagerProvider = NotifierProvider<AutoSyncManager, SyncState>(() {
  return AutoSyncManager();
});

class AutoSyncManager extends Notifier<SyncState> with WindowListener {
  Timer? _periodicTimer;
  Timer? _debounceTimer;
  
  @override
  SyncState build() {
    _init();
    ref.onDispose(() {
      windowManager.removeListener(this);
      _periodicTimer?.cancel();
      _debounceTimer?.cancel();
    });
    return SyncState.idle;
  }

  void _init() {
    windowManager.addListener(this);
    // 週期性同步：10 分鐘
    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _executeSync(triggerSource: 'periodic_timer', isManual: false);
    });
    
    // 啟動時立刻觸發一次
    Future.microtask(() => _executeSync(triggerSource: 'app_launch', isManual: false));
  }

  @override
  void onWindowFocus() {
    // 當視窗重新獲得焦點時（喚醒），執行同步
    _executeSync(triggerSource: 'window_focus', isManual: false);
  }

  /// 資料變更後呼叫此方法，使用 30 秒防抖
  void scheduleSyncAfterMutation() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 30), () {
      _executeSync(triggerSource: 'mutation_debounce', isManual: false);
    });
  }

  /// 手動觸發同步
  Future<void> manualSync() async {
    _debounceTimer?.cancel();
    await _executeSync(triggerSource: 'manual_trigger', isManual: true);
  }

  Future<void> _executeSync({required String triggerSource, required bool isManual}) async {
    if (state != SyncState.idle) return;
    
    // 檢查是否已登入
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) return;

    try {
      state = isManual ? SyncState.manual : SyncState.auto;
      debugPrint('AutoSyncManager: Triggered sync via $triggerSource');
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncWithDropbox();
      
      // 更新最後同步時間
      ref.read(settingsProvider.notifier).updateLastSyncTime(DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('AutoSyncManager: Sync failed ($triggerSource) - $e');
    } finally {
      state = SyncState.idle;
    }
  }
}
