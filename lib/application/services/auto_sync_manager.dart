import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'sync_service.dart';
import '../../presentation/providers/auth_provider.dart';
import '../../presentation/providers/settings_provider.dart';

enum SyncState { idle, manual, auto }

final autoSyncManagerProvider = NotifierProvider<AutoSyncManager, SyncState>(
  () {
    return AutoSyncManager();
  },
);

class AutoSyncManager extends Notifier<SyncState> {
  Timer? _periodicTimer;

  @override
  SyncState build() {
    _init();
    ref.onDispose(() {
      _periodicTimer?.cancel();
    });
    return SyncState.idle;
  }

  void _init() {
    // 週期性同步：10 分鐘
    _periodicTimer = Timer.periodic(const Duration(minutes: 10), (_) {
      _executeSync(triggerSource: 'periodic_timer', isManual: false);
    });

    // 啟動時立刻觸發一次
    Future.microtask(
      () => _executeSync(triggerSource: 'app_launch', isManual: false),
    );
  }

  /// 手動觸發同步
  Future<bool> manualSync() async {
    return await _executeSync(triggerSource: 'manual_trigger', isManual: true);
  }

  Future<bool> _executeSync({
    required String triggerSource,
    required bool isManual,
  }) async {
    if (state != SyncState.idle) return false;

    // 檢查是否已登入
    final isLoggedIn = ref.read(authProvider).isLoggedIn;
    if (!isLoggedIn) return false;

    try {
      state = isManual ? SyncState.manual : SyncState.auto;
      debugPrint('AutoSyncManager: Triggered sync via $triggerSource');
      final syncService = ref.read(syncServiceProvider);
      await syncService.syncWithDropbox();

      // 更新最後同步時間
      ref
          .read(settingsProvider.notifier)
          .updateLastSyncTime(DateTime.now().toIso8601String());
      return true;
    } catch (e) {
      debugPrint('AutoSyncManager: Sync failed ($triggerSource) - $e');
      return false;
    } finally {
      state = SyncState.idle;
    }
  }
}
