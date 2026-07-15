<div align="center">
  <img src="Screenshot/image.png" alt="Zenist Banner" width="100%">
  
  <br />
  
  [![Release](https://img.shields.io/github/v/release/ChiesiMario/Zenist?color=black&style=flat-square)](https://github.com/ChiesiMario/Zenist/releases)
  [![Platform](https://img.shields.io/badge/Platform-Windows_(Currently)-lightgrey?style=flat-square)](#)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-black?style=flat-square)](https://flutter.dev)
  [![License](https://img.shields.io/github/license/ChiesiMario/Zenist?color=black&style=flat-square)](LICENSE)
</div>

# Zenist

English | [繁體中文](README_zh-TW.md) | [简体中文](README_zh-CN.md)

---

**Zenist** is a minimalist, offline-first task management application designed for deep focus. *(Currently available on Windows, with cross-platform support planned for the future).*

The core philosophy of Zenist is built upon three uncompromising principles:
* **Simple**: A pure, monochrome, distraction-free interface.
* **No Push Notifications**: Respecting your attention without unwanted interruptions.
* **Bring Your Own Cloud**: Your data is synchronized entirely through your personal cloud drive (Dropbox), ensuring absolute privacy and data ownership.

## ✨ Key Features
* **Minimalist UI**: Designed with a sleek black, white, and grey palette to keep you focused on what truly matters.
* **Background Execution**: Minimizes quietly to the system tray for seamless operation.
* **Single Instance Protection**: Optimized to run lightly on your system without duplicate processes.
* **Offline First**: Works entirely offline with a blazing-fast local database, syncing quietly in the background when connected.
* **Clean Uninstallation**: Intelligent installer that gracefully handles background processes and registry cleanups.

## 🛠️ Tech Stack
Zenist is proudly built with modern technologies, laying the groundwork for its future cross-platform expansion:
- **Framework**: [Flutter](https://flutter.dev/)
- **State Management**: [Riverpod](https://riverpod.dev/)
- **Local Database**: [Isar](https://isar.dev/) (High-performance NoSQL)
- **UI Components**: [Shadcn UI for Flutter](https://shadcn-ui.dev/)
- **Cloud Sync**: Official Dropbox API

## 🚀 Getting Started

### Download & Install
You can download the latest installer (`.exe`) from the [Releases](https://github.com/ChiesiMario/Zenist/releases/latest) page.

### Build from Source
If you wish to build Zenist from source or contribute to the project:

1. Ensure you have [Flutter](https://docs.flutter.dev/get-started/install) installed.
2. Clone this repository:
   ```bash
   git clone https://github.com/ChiesiMario/Zenist.git
   cd Zenist
   ```
3. Install dependencies:
   ```bash
   flutter pub get
   ```
4. Run locally (currently supporting Windows):
   ```bash
   flutter run -d windows
   ```
5. Build the executable:
   ```bash
   flutter build windows
   ```
*(To build the installer, compile `windows/zenist_installer.iss` using Inno Setup).*

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.