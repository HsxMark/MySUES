<p align="center">
  <img src="../assets/images/example/MySUES-1024x1024@1x.png" width="150" alt="MySUES Logo">
</p>

# MySUES (苏伊士)

**简体中文** | [English](../README.md)

MySUES 是由上海工程技术大学（SUES）学生开发者制作的一款校园生活助手 App。旨在为 SUESer 提供更便捷的教务信息查询服务，支持 iOS 和 Android 双端。

## ✨ 功能特性

- **📅 课表查询**：随时随地查看课程安排，不仅支持在线教务系统数据同步，还提供直观的周视图。
- **📊 成绩查询**：快速查询各学期成绩绩点，掌握学习进度。
- **📝 考试信息**：查看考试时间、地点安排，不再错过任何一场考试。
- **📄 PDF 导入**：支持导入学校下发的 PDF 格式课表，离线也能看。
- **🎨 个性化设置**：支持深色模式（Dark Mode），可自定义字体，打造专属应用体验。
- **🔒 安全登录**：内置 WebView 登录教务系统，通过 Cookie 管理保持会话，安全便捷。

## 🛠️ 技术栈

本项目使用 Google [Flutter](https://flutter.dev) 框架开发。

### 主要依赖
- **网络请求**: [dio](https://pub.dev/packages/dio), [cookie_jar](https://pub.dev/packages/cookie_jar)
- **PDF 处理**: [syncfusion_flutter_pdf](https://pub.dev/packages/syncfusion_flutter_pdf)
- **WebView**: [webview_flutter](https://pub.dev/packages/webview_flutter)
- **本地存储**: [shared_preferences](https://pub.dev/packages/shared_preferences)
- **文件选择**: [file_picker](https://pub.dev/packages/file_picker)

## 🚀 快速开始

如果你想在本地运行本项目，请确保你已经安装了 Flutter 开发环境。

1. **克隆项目**
   ```bash
   git clone https://github.com/HsxMark/MySUES.git
   cd MySUES
   ```

2. **安装依赖**
   ```bash
   flutter pub get
   ```

3. **运行应用**
   ```bash
   flutter run
   ```

## 📱 平台支持

- **Android**: Android 12.0+
- **iOS**: iOS 14.0+

## ⚠️ 免责声明

本项目为学生个人开发的的非官方应用，仅供学习交流使用。
- 应用内所有数据均直接来源于学校教务系统，本项目不保存任何用户的账号密码。
- 请勿将本项目用于任何商业用途。

## 📜 开源协议

本项目遵循开源协议，详情请查看 [LICENSE](../LICENSE) 文件。
