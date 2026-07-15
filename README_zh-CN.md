<div align="center">
  <img src="Screenshot/image.png" alt="Zenist Banner" width="100%">
  
  <br />
  
  [![Release](https://img.shields.io/github/v/release/ChiesiMario/Zenist?color=black&style=flat-square)](https://github.com/ChiesiMario/Zenist/releases)
  [![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey?style=flat-square)](#)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-black?style=flat-square)](https://flutter.dev)
  [![License](https://img.shields.io/github/license/ChiesiMario/Zenist?color=black&style=flat-square)](LICENSE)
</div>

# Zenist

[English](README.md) | [繁體中文](README_zh-TW.md) | 简体中文

---

**Zenist** 是一款专为 Windows 打造，专注于极简与离线优先的待办事项管理工具。

Zenist 的设计核心建立于以下三大绝不妥协的理念：
* **简单**：纯粹、无干扰的黑白灰界面设计。
* **无推送**：不打扰您的注意力，拒绝任何非必要的通知。
* **通过自己的云盘同步**：所有数据皆通过您个人的云盘（Dropbox）进行同步，确保数据的绝对隐私与所有权。

## ✨ 核心特色
* **极简界面**：采用最克制的黑白灰纯粹视觉，让您全神贯注于当下的任务。
* **后台运行**：无缝支持常驻系统托盘，随点随唤醒，不占用任务栏空间。
* **单一实例防护**：完美控制系统资源，防止软件被重复启动（多开）。
* **离线优先 (Offline-First)**：搭配极速的本地数据库，无需网络即可获得最流畅的操作体验，并在连线时于后台安静同步。
* **纯净卸载**：安装与卸载过程皆具备智能防护，自动清理注册表与强制关闭后台进程，不留垃圾。

## 🛠️ 技术架构
Zenist 采用现代化、高效的跨平台技术栈开发：
- **核心框架**：[Flutter](https://flutter.dev/) (Desktop)
- **状态管理**：[Riverpod](https://riverpod.dev/)
- **本地数据库**：[Isar](https://isar.dev/) (高性能 NoSQL)
- **UI 组件库**：[Shadcn UI for Flutter](https://shadcn-ui.dev/)
- **云端同步**：Official Dropbox API

## 🚀 快速开始

### 下载安装
请前往 [Releases](https://github.com/ChiesiMario/Zenist/releases/latest) 页面下载最新版本的 Windows 安装程序 (`.exe`)。

### 从源码编译
如果您希望亲手编译 Zenist 或是参与开源贡献：

1. 请确保您的电脑已经安装好 [Flutter](https://docs.flutter.dev/get-started/install/windows) 开发环境。
2. 克隆此仓库：
   ```bash
   git clone https://github.com/ChiesiMario/Zenist.git
   cd Zenist
   ```
3. 安装依赖包：
   ```bash
   flutter pub get
   ```
4. 在本地运行：
   ```bash
   flutter run -d windows
   ```
5. 编译成 Windows 执行文件：
   ```bash
   flutter build windows
   ```
*(若要制作安装包，您需要安装 Inno Setup 并编译 `windows/zenist_installer.iss` 脚本)。*

## 📄 开源协议
本项目采用 MIT 授权协议，详细信息请参阅 [LICENSE](LICENSE) 文件。
