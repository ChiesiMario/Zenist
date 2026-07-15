import 'dart:io';
import 'package:win32_registry/win32_registry.dart';
import 'package:package_info_plus/package_info_plus.dart';

class StartupService {
  static const String _registryKeyPath = r'Software\Microsoft\Windows\CurrentVersion\Run';

  static Future<void> enable() async {
    if (!Platform.isWindows) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      final appPath = Platform.resolvedExecutable;
      
      final key = CURRENT_USER.create(_registryKeyPath);
      final execPath = '"$appPath" --minimized';
      
      key.setValue(
        appName,
        RegistryValue.string(execPath),
      );
      key.close();
    } catch (e) {
      print('Error enabling startup: $e');
    }
  }

  static Future<void> disable() async {
    if (!Platform.isWindows) return;
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appName = packageInfo.appName;
      
      final key = CURRENT_USER.open(
        _registryKeyPath,
        config: const RegistryOpenConfig(access: RegistryAccess.all),
      );
      // key will be returned if open succeeds, otherwise throws.
      // Wait, let's just do CURRENT_USER.create because it's safer if it doesn't exist.
      // removeValue will throw if value not found, so we catch it.
      try {
        key.removeValue(appName);
      } catch (_) {}
      key.close();
    } catch (e) {
      print('Error disabling startup: $e');
    }
  }
}
