# Zenist.

[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

> 一款專注於清晰度與生產力的極簡任務管理應用程式。

![Version](https://img.shields.io/badge/version-1.0.1-black?style=flat-square&labelColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-black?style=flat-square&labelColor=white)
![License](https://img.shields.io/badge/license-MIT-black?style=flat-square&labelColor=white)

<br>
<p align="center">
  <img src="Screenshot/image.png" alt="Zenist Screenshot" width="800">
</p>
<br>

## 核心功能

- **清晰至上**：嚴格貫徹黑白灰單色美學的無干擾介面，摒棄所有表情符號與過度飽和的色彩。
- **本地儲存**：所有資料均儲存於您的設備本機，確保絕對的隱私與極致的操作反應速度。
- **重複任務**：提供每日、每週、每月或自訂週期的彈性任務排程。
- **子任務與備註**：將複雜目標拆解為具體的可執行步驟，並支援添加文字備註。
- **系統整合**：無縫的視窗管理，支援系統列 (Tray) 縮小與背景執行。
- **國際化支援**：完整支援多國語言介面。

## 技術棧

- **框架**: Flutter / Dart
- **狀態管理**: Riverpod
- **本地資料庫**: Isar
- **介面元件**: Shadcn UI

## 安裝方式

### 直接安裝 (Windows)

1. 前往 [Releases](https://github.com/ChiesiMario/Zenist/releases) 頁面。
2. 下載最新的安裝檔 `Zenist-Setup-vX.X.X.exe`。
3. 執行安裝程式並依照指示完成安裝。

### 從原始碼編譯

請確認您的系統已安裝 Flutter SDK (>=3.12.2)。

```bash
git clone https://github.com/ChiesiMario/Zenist.git
cd Zenist
flutter pub get
flutter build windows
```

## 系統架構

Zenist 遵循乾淨且模組化的架構設計，將展示層、領域層與資料層徹底分離：

- `presentation/`：Riverpod 狀態提供者、UI 元件與對話框。
- `domain/`：核心實體物件與業務邏輯。
- `core/`：應用程式共用工具、主題定義與多國語系設定。

## 授權條款

本專案採用 MIT 授權條款。
