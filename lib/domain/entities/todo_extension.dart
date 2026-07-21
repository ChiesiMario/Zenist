import 'todo.dart';
import '../../core/localization/translations.dart';
import '../../core/utils/date_formatter.dart';

extension TodoFormatting on Todo {
  /// 獲取格式化的到期日字串 (例如：「明天 · 每 1 天」)
  String getFormattedDateString(String locale, String dateFormat) {
    String dateStr = '';
    if (isAnytime || dueDate != null) {
      dateStr = DateFormatter.getRelativeDateString(
        date: dueDate,
        locale: locale,
        dateFormat: dateFormat,
        isAnytime: isAnytime,
        includeAbsolute: false,
      );
    }

    final isHistoryLog = isCompleted &&
        completedAt != null &&
        completionHistory.any((r) => r.completedAt == completedAt!);

    if (repeatInterval != null && repeatUnit != null) {
      final repeatStr =
          '${Translations.tr('every', locale)}$repeatInterval ${_getRepeatUnitLabel(repeatUnit!, locale)}';

      if (isHistoryLog && dateStr.isNotEmpty) {
        dateStr = '${Translations.tr('next_time', locale)}$dateStr';
      }

      return dateStr.isEmpty ? repeatStr : '$dateStr · $repeatStr';
    }

    return dateStr;
  }

  String _getRepeatUnitLabel(String unit, String locale) {
    switch (unit) {
      case 'day':
        return Translations.tr('unit_day', locale);
      case 'week':
        return Translations.tr('unit_week', locale);
      case 'month':
        return Translations.tr('unit_month', locale);
      case 'year':
        return Translations.tr('unit_year', locale);
      default:
        return '';
    }
  }
}
