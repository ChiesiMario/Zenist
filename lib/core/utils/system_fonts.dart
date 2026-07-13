import 'dart:io';

class SystemFontsHelper {
  /// Fetches system fonts using a platform-specific command.
  /// Currently implemented for Windows.
  static Future<List<String>> getSystemFonts() async {
    if (!Platform.isWindows) {
      return ['NotoSansTC']; // Fallback for unsupported platforms
    }

    try {
      final result = await Process.run(
        'powershell',
        [
          '-Command',
          'Add-Type -AssemblyName System.Drawing; [System.Drawing.FontFamily]::Families | Select-Object -ExpandProperty Name'
        ],
      );

      if (result.exitCode == 0) {
        final String output = result.stdout;
        final lines = output.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        // Return unique fonts sorted alphabetically
        final uniqueFonts = lines.toSet().toList()..sort();
        return uniqueFonts;
      }
    } catch (e) {
      // Ignore errors and fallback
    }
    
    return ['NotoSansTC', 'Arial', 'Segoe UI', 'Times New Roman']; // Fallback list
  }
}
