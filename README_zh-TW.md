<div align="center">
  <img src="Screenshot/image.png" alt="Zenist Banner" width="100%">
  
  <br />
  
  [![Release](https://img.shields.io/github/v/release/ChiesiMario/Zenist?color=black&style=flat-square)](https://github.com/ChiesiMario/Zenist/releases)
  [![Platform](https://img.shields.io/badge/Platform-Windows_(目前)-lightgrey?style=flat-square)](#)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-black?style=flat-square)](https://flutter.dev)
  [![License](https://img.shields.io/github/license/ChiesiMario/Zenist?color=black&style=flat-square)](LICENSE)
</div>

# Zenist

[English](README.md) | 繁體中文 | [简体中文](README_zh-CN.md)

---

**Zenist** 是一款專注於極簡與離線優先的待辦事項管理工具。*(本專案擁有全平台的發展計畫，目前暫時僅提供 Windows 版本)*。

Zenist 的設計核心建立於以下三大絕不妥協的理念：
* **簡單**：純粹、無干擾的黑白灰介面設計。
* **無推送**：不打擾您的注意力，拒絕任何非必要的通知。
* **透過自己的雲端硬碟同步**：所有數據皆透過您個人的雲端硬碟（Dropbox）進行同步，確保資料的絕對隱私與所有權。

## ✨ 核心特色
* **極簡介面**：採用最克制的黑白灰純粹視覺，讓您全神貫注於當下的任務。
* **背景執行**：無縫支援常駐系統匣，隨點隨喚醒。
* **單一實例防護**：完美控制系統資源，防止軟體被重複啟動（多開）。
* **離線優先 (Offline-First)**：搭配極速的本機端資料庫，無需網路即可獲得最流暢的操作體驗，並在連線時於背景安靜同步。
* **純淨解除安裝**：安裝與解除安裝過程皆具備智能防護，自動清理登錄檔與強制關閉背景程序。

## 🛠️ 技術架構
Zenist 採用現代化的跨平台技術棧開發，為未來的全平台支援打下堅實基礎：
- **核心框架**：[Flutter](https://flutter.dev/)
- **狀態管理**：[Riverpod](https://riverpod.dev/)
- **本機資料庫**：[Isar](https://isar.dev/) (高效能 NoSQL)
- **UI 元件庫**：[Shadcn UI for Flutter](https://shadcn-ui.dev/)
- **雲端同步**：Official Dropbox API

## 🚀 快速開始

### 下載安裝
請前往 [Releases](https://github.com/ChiesiMario/Zenist/releases/latest) 頁面下載最新版本的安裝檔 (`.exe`)。

### 從原始碼編譯
如果您希望親手編譯 Zenist 或是參與開源貢獻：

1. 請確保您的電腦已經安裝好 [Flutter](https://docs.flutter.dev/get-started/install)。
2. 複製此儲存庫：
   ```bash
   git clone https://github.com/ChiesiMario/Zenist.git
   cd Zenist
   ```
3. 安裝依賴套件：
   ```bash
   flutter pub get
   ```
4. 在本機端執行（目前支援 Windows）：
   ```bash
   flutter run -d windows
   ```
5. 編譯成執行檔：
   ```bash
   flutter build windows
   ```
*(若要製作 Windows 安裝檔，您需要安裝 Inno Setup 並編譯 `windows/zenist_installer.iss` 腳本)。*

## 📄 開源協議
本專案採用 MIT 授權條款，詳細資訊請參閱 [LICENSE](LICENSE) 檔案。
