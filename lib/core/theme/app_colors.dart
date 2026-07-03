import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Vercel 色彩系統
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  
  static const Color vercelBlue = Color(0xFF0070F3);
  static const Color vercelGray900 = Color(0xFF111111);
  static const Color vercelGray800 = Color(0xFF333333);
  static const Color vercelGray700 = Color(0xFF444444);
  static const Color vercelGray600 = Color(0xFF666666); // 次要文字
  static const Color vercelGray500 = Color(0xFF888888);
  static const Color vercelGray400 = Color(0xFFAAAAAA);
  static const Color vercelGray300 = Color(0xFFCCCCCC);
  static const Color vercelGray200 = Color(0xFFEAEAEA); // 精細邊框
  static const Color vercelGray100 = Color(0xFFF5F5F5); // Hover
  static const Color vercelGray50  = Color(0xFFFAFAFA); // 背景色
  static const Color transparent = Color(0x00000000);

  // 語意化命名
  static const Color background = vercelGray50; // 整個 App 背景用微灰
  static const Color cardBackground = white;    // 內容卡片用純白
  static const Color textPrimary = black;       // Vercel 的純黑高對比
  static const Color textSecondary = vercelGray600; 
  static const Color divider = vercelGray200;   // 經典 1px EAEAEA
  static const Color highlight = vercelGray100;
  static const Color accent = vercelBlue;
}
