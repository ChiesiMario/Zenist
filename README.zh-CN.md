# ZENIST

[English](README.md) | [繁體中文](README.zh-TW.md) | [简体中文](README.zh-CN.md)

> 一款专注于清晰度与生产力的极简任务管理应用程序。

![Version](https://img.shields.io/badge/version-1.0.1-black?style=flat-square&labelColor=white)
![Platform](https://img.shields.io/badge/platform-Windows-black?style=flat-square&labelColor=white)
![License](https://img.shields.io/badge/license-MIT-black?style=flat-square&labelColor=white)

---

## 核心功能

- **清晰至上**：严格贯彻黑白灰单色美学的无干扰界面，摒弃所有表情符号与过度饱和的色彩。
- **本地存储**：所有数据均存储于您的设备本地，确保绝对的隐私与极致的操作响应速度。
- **重复任务**：提供每日、每周、每月或自定义周期的弹性任务排程。
- **子任务与备注**：将复杂目标拆解为具体的可执行步骤，并支持添加文字备注。
- **系统整合**：无缝的窗口管理，支持系统托盘 (Tray) 缩小与后台运行。
- **国际化支持**：完整支持多国语言界面。

## 技术栈

- **框架**: Flutter / Dart
- **状态管理**: Riverpod
- **本地数据库**: Isar
- **界面组件**: Shadcn UI

## 安装方式

### 直接安装 (Windows)

1. 前往 [Releases](https://github.com/ChiesiMario/Zenist/releases) 页面。
2. 下载最新的安装包 `Zenist-Setup-vX.X.X.exe`。
3. 运行安装程序并按照指示完成安装。

### 从源码编译

请确认您的系统已安装 Flutter SDK (>=3.12.2)。

```bash
git clone https://github.com/ChiesiMario/Zenist.git
cd Zenist
flutter pub get
flutter build windows
```

## 系统架构

Zenist 遵循干净且模块化的架构设计，将展示层、领域层与数据层彻底分离：

- `presentation/`：Riverpod 状态提供者、UI 组件与对话框。
- `domain/`：核心实体对象与业务逻辑。
- `core/`：应用程序共用工具、主题定义与多国语言设置。

## 授权条款

本项目采用 MIT 授权条款。
