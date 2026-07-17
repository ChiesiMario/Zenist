import 'package:intl/intl.dart';
import '../localization/translations.dart';

class DateFormatter {
  /// Returns a formatted relative date string (e.g., 'Yesterday (2026/07/15)').
  /// 
  /// [date] The target date to format.
  /// [locale] The current language locale.
  /// [dateFormat] The absolute date format string (e.g., 'yyyy/MM/dd').
  /// [isAnytime] Whether the task is marked as anytime.
  /// [includeAbsolute] Whether to append the absolute date in parentheses.
  static String getRelativeDateString({
    required DateTime? date,
    required String locale,
    required String dateFormat,
    bool isAnytime = false,
    bool includeAbsolute = false,
  }) {
    if (isAnytime) {
      return Translations.tr('tab_anytime', locale);
    }
    
    if (date == null) {
      return '';
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    
    final differenceInDays = targetDate.difference(today).inDays;
    
    String relativeStr = '';
    bool hasRelative = true;

    if (differenceInDays == 0) {
      relativeStr = Translations.tr('tab_today', locale);
    } else if (differenceInDays == 1) {
      relativeStr = Translations.tr('tomorrow', locale);
    } else if (differenceInDays == 2) {
      relativeStr = Translations.tr('day_after_tomorrow', locale);
    } else if (differenceInDays >= 3 && differenceInDays <= 6) {
      relativeStr = Translations.tr('days_later', locale)
          .replaceAll('{days}', differenceInDays.toString());
    } else if (differenceInDays == 7) {
      relativeStr = Translations.tr('1_week_later', locale);
    } else if (differenceInDays == -1) {
      relativeStr = Translations.tr('yesterday', locale);
    } else if (differenceInDays == -2) {
      relativeStr = Translations.tr('day_before_yesterday', locale);
    } else if (differenceInDays <= -3 && differenceInDays >= -6) {
      relativeStr = Translations.tr('days_ago', locale)
          .replaceAll('{days}', differenceInDays.abs().toString());
    } else if (differenceInDays == -7) {
      relativeStr = Translations.tr('1_week_ago', locale);
    } else {
      hasRelative = false;
    }

    final absoluteStr = DateFormat(dateFormat).format(date);

    if (!hasRelative) {
      return absoluteStr;
    }

    if (includeAbsolute) {
      return '$relativeStr ($absoluteStr)';
    }

    return relativeStr;
  }
}
