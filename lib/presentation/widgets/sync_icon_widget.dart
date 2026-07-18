import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../application/services/auto_sync_manager.dart';
import '../providers/auth_provider.dart';
import '../../core/utils/toast_utils.dart';

class SyncIconWidget extends ConsumerStatefulWidget {
  const SyncIconWidget({super.key});

  @override
  ConsumerState<SyncIconWidget> createState() => _SyncIconWidgetState();
}

class _SyncIconWidgetState extends ConsumerState<SyncIconWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  bool? _lastSyncSuccess;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      lowerBound: 0.3,
      upperBound: 1.0,
    );
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = ref.watch(authProvider).isLoggedIn;
    final syncState = ref.watch(autoSyncManagerProvider);

    if (syncState == SyncState.manual) {
      _pulseController.stop();
      _rotationController.repeat();
    } else if (syncState == SyncState.auto) {
      _rotationController.stop();
      _pulseController.repeat(reverse: true);
    } else {
      _rotationController.stop();
      _rotationController.reset();
      _pulseController.stop();
      _pulseController.value = 1.0;
    }

    IconData iconData;
    Color? iconColor;

    if (!isLoggedIn) {
      iconData = LucideIcons.cloudOff;
      iconColor = ShadTheme.of(
        context,
      ).colorScheme.mutedForeground.withValues(alpha: 0.5);
    } else if (syncState == SyncState.manual) {
      iconData = LucideIcons.loader2;
      iconColor = ShadTheme.of(context).colorScheme.primary;
    } else if (syncState == SyncState.auto) {
      iconData = LucideIcons.cloud;
      iconColor = ShadTheme.of(context).colorScheme.primary;
    } else if (_lastSyncSuccess != null) {
      iconData = _lastSyncSuccess! ? LucideIcons.check : LucideIcons.x;
      iconColor = _lastSyncSuccess!
          ? const Color(0xFF10B981) // Green for success
          : ShadTheme.of(context).colorScheme.destructive; // Red for fail
    } else {
      iconData = LucideIcons.cloud;
      iconColor = ShadTheme.of(
        context,
      ).colorScheme.mutedForeground.withValues(alpha: 0.5);
    }

    Widget iconWidget = Icon(iconData, size: 24, color: iconColor);

    if (syncState == SyncState.manual) {
      iconWidget = RotationTransition(
        turns: _rotationController,
        child: iconWidget,
      );
    } else if (syncState == SyncState.auto) {
      iconWidget = FadeTransition(opacity: _pulseController, child: iconWidget);
    }

    return ShadButton.ghost(
      onPressed: () async {
        if (!isLoggedIn) {
          ToastUtils.show(context, '請先前往「設置」頁面登入 Dropbox 以啟用雲端同步功能。');
        } else if (syncState == SyncState.idle) {
          final success = await ref.read(autoSyncManagerProvider.notifier).manualSync();
          if (mounted) {
            ToastUtils.show(context, success ? '同步成功' : '同步失敗');
            setState(() {
              _lastSyncSuccess = success;
            });
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                setState(() {
                  _lastSyncSuccess = null;
                });
              }
            });
          }
        }
      },
      width: 36,
      height: 36,
      padding: EdgeInsets.zero,
      child: iconWidget,
    );
  }
}
