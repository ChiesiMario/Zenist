import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // 極簡灰階色彩系統
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);

  static const Color gray900 = Color(0xFF111111);
  static const Color gray800 = Color(0xFF333333);
  static const Color gray700 = Color(0xFF555555);
  static const Color gray600 = Color(0xFF777777);
  static const Color gray500 = Color(0xFF999999);
  static const Color gray400 = Color(0xFFBBBBBB);
  static const Color gray300 = Color(0xFFDDDDDD);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray50  = Color(0xFFFAFAFA);
  static const Color transparent = Color(0x00000000);

  // 語意化命名
  static const Color background = white;
  static const Color textPrimary = gray900;
  static const Color textSecondary = gray500;
  static const Color divider = gray200;
  static const Color highlight = gray100;
}
