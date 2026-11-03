# Flash Translate

极简 macOS 菜单栏划词翻译工具

## ✨ 特性

- **双击 Command 键即可翻译** - 选中文字后快速双击 Command，悬浮窗自动出现在鼠标附近
- **原生 SwiftUI** - 纯 Swift 编写，零延迟体验
- **支持多种翻译服务** - 默认 Google Translate，支持 DeepL API 和自定义 OpenAI-compatible API
- **菜单栏常驻** - 不占 Dock 位置，随时可用
- **优雅动画** - 淡入淡出效果，流畅自然
- **智能边界检测** - 悬浮窗自动避开屏幕边缘

## 🎯 产品理念

专注一个功能并做到极致。不做加法，只做减法。

## 📦 安装

1. 下载 [FlashTranslate-v1.0.dmg](https://github.com/YOUR_USERNAME/Flash-Translate/releases/download/v1.0/FlashTranslate-v1.0.dmg)
2. 打开 DMG 文件
3. 将 Flash Translate 拖到应用程序文件夹
4. 首次运行需要授予辅助功能权限

## 🚀 使用方法

1. **双击 Command** - 在任何地方选中文字，快速双击 Command 键
2. **点击菜单栏图标** - 手动输入文字翻译
3. **右键菜单栏图标** - 打开设置、授权权限

## ⚙️ 设置

- **翻译服务** - 选择 Google、DeepL 或 OpenAI Compatible
- **DeepL API** - 选择 Free 或 Pro，填写对应的 DeepL API Key；两种方案分别连接 `api-free.deepl.com` 和 `api.deepl.com`，API Key 与 OpenAI 配置分别保存。需要 DeepL API 订阅，普通 DeepL Pro 翻译订阅不等同于 API 订阅。
- **OpenAI Compatible** - Base URL 填写包含 `/v1` 的接口地址，并配置 API Key 和 Model。
- **Thinking effort** - 默认不发送参数；可选择 `none`、`minimal`、`low`、`medium`、`high`、`xhigh`、`max`，通过 Chat Completions 的 `reasoning_effort` 字段发送。各接口与模型支持的档位不同，不支持时请切回默认。
- **测试翻译** - DeepL 和 OpenAI Compatible 均可在设置中测试当前配置。
- **快捷键** - 默认双击 Command，也可自定义快捷键

API Key 沿用项目现有方式保存在本机 UserDefaults 中。升级时会保留旧版 API 和快捷键配置。

接口参考：[DeepL 文本翻译](https://developers.deepl.com/api-reference/translate)、[OpenAI Chat Completions](https://developers.openai.com/api/reference/resources/chat/subresources/completions/methods/create)。

## 本地开发

需要 macOS 14 或更新版本，以及支持 Swift 5.9 的 Xcode / Swift 工具链。

```sh
swift test
swift build -c release
```

也可使用 Xcode 打开 `FlashTranslate.xcodeproj` 构建应用。

## 🛠 技术栈

- SwiftUI + AppKit
- Accessibility API
- 纯原生实现，无第三方依赖

## 📝 开发日志

详见 [log.md](log.md)

## 📄 许可证

**专有软件 - 仅供个人使用**

本软件源代码仅供学习和参考。未经许可，禁止商业使用、修改或分发。

详见 [LICENSE](LICENSE) 文件。

## 🙏 致谢

使用 Claude Code 开发完成
