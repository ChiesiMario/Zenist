import 'dart:io';
import 'dart:convert';

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
          '[Console]::OutputEncoding = [System.Text.Encoding]::UTF8; Add-Type -AssemblyName System.Drawing; [System.Drawing.FontFamily]::Families | Select-Object -ExpandProperty Name'
        ],
        stdoutEncoding: utf8,
      );

      if (result.exitCode == 0) {
        final String output = result.stdout;
        final lines = output.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toSet();
        
        // 強制無條件合併演算法：
        // 許多字體（例如 Barlow Condensed Black）即使沒有安裝主字體，我們也一律將後綴拔除，
        // 並將相同主名稱的結果強行合併，呈現最乾淨的家族列表。
        final variants = [
          'light', 'bold', 'black', 'thin', 'medium', 'regular', 
          'italic', 'oblique', 'semibold', 'extrabold', 'extralight',
          'semilight', 'ui', 'heavy', 'normal', 'condensed', 
          'semicondensed', 'xlight', 'book',
          '中粗體', '中黑體', '極細體', '細體', '纖細體'
        ];

        final Set<String> mergedFonts = {};

        for (final font in lines) {
          String currentBase = font;
          bool changed = true;
          
          // 反覆剝離後綴，直到無法再剝離為止
          while (changed) {
            changed = false;
            for (final variant in variants) {
              final suffix = ' $variant';
              if (currentBase.toLowerCase().endsWith(suffix.toLowerCase())) {
                currentBase = currentBase.substring(0, currentBase.length - suffix.length);
                changed = true;
                break;
              }
            }
          }
          
          // 無條件將剝離後的乾淨主名稱加入 Set（自動去重）
          if (currentBase.trim().isNotEmpty) {
            mergedFonts.add(currentBase);
          } else {
            mergedFonts.add(font); // 防呆，萬一全部被剝光了就保留原名
          }
        }

        final uniqueFonts = mergedFonts.toList()..sort();
        return uniqueFonts;
      }
    } catch (e) {
      // Ignore errors and fallback
    }
    
    return ['NotoSansTC', 'Arial', 'Segoe UI', 'Times New Roman']; // Fallback list
  }
}
