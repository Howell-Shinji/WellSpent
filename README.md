# WellSpent v2

> 置顶浮动的 Tokyo Night 待办小窗 · a focused floating todo app for macOS

一个一直飘在屏幕角落的小窗口，提醒你今天该做什么。写进去、做完了、划掉，一天就有了形状。

<p align="center">
  <img src="attachments/screenshot-v2.png" alt="WellSpent app screenshot" width="380">
</p>

## v2.0.0 更新

- 删除和清除已完成后，可用界面上的“撤销”恢复最近一次删除；后续新增内容不会被覆盖。撤销记录只保留在当前运行期间。
- 编辑支持保存、取消、失焦提交；空内容保留原任务，长文本支持展开。
- 每次操作立即保存，保留上一份有效备份；保存失败可重试，退出前会提示未保存的更改。
- 读取异常时尝试恢复有效备份并保留原文件；没有可用备份时阻止覆盖，提供重试和打开数据文件夹入口。
- 记住窗口位置与尺寸，显示器断开后将窗口移回可见区域；设置中可关闭置顶。
- 未完成任务优先，已完成项可折叠；计数改为“剩余 N 项”，不再暗示按天统计。
- 本次没有新增快捷键；保留原有的 Enter 提交和 Esc 取消。

## 核心特性

- 🪟 **置顶浮动** — 默认置顶，也可在设置中关闭
- 🖱️ **可拖动** — 点背景拖动，重启后恢复上次位置与尺寸
- 👻 **透明度可调** — 30%–100% 自由调，不挡事
- 🌃 **Tokyo Night 视觉** — 以夜间与 Light 调色板为基础，清晰区分内容、状态与操作
- 🌓 **三档外观** — 可跟随 macOS，也可手动固定浅色或深色
- 💾 **本地持久化** — 数据保存在 `~/Library/Application Support/WellSpent/`，不会联网

## 使用

- 回车 / 点输入框右侧箭头 — 添加待办
- 点复选框 — 完成 / 取消完成
- 双击文字 — 编辑；点击保存或回车提交，取消或 Esc 放弃修改，点击别处提交非空修改
- 点垃圾桶 — 删除；底部“撤销”恢复最近一次删除
- 点“已完成” — 展开或折叠完成项
- 点“展开全文” — 查看长任务
- 点标题右侧齿轮 — 选择外观模式、置顶或透明度

## 安装

### 方式一：下载 DMG（推荐）

到 [Releases](../../releases) 下载最新版 DMG，双击打开，把 `WellSpent.app` 拖进 Applications。

> ⚠️ 未代码签名。首次启动会被 Gatekeeper 拦，解决办法：**右键点 app 图标 → 选「打开」→ 弹窗里再点一次「打开」**。之后正常双击即可。

### 方式二：从源码构建

需要 macOS 13+ 和 Xcode Command Line Tools。

下载或克隆本仓库后，在项目根目录运行：

```bash
./WellSpent/scripts/build.sh
open "WellSpent/build/WellSpent.app"
```

打包 DMG：

```bash
./WellSpent/scripts/package-dmg.sh           # 从应用读取版本号，当前为 2.0.0
bash ./WellSpent/scripts/test.sh            # 使用临时数据运行回归测试
```

## 技术栈

- SwiftUI + AppKit (NSApplicationDelegate 配置 NSWindow)
- Foundation + Combine（同步原子保存、备份与状态更新）
- 零第三方依赖
- 直接 `swiftc` 编译 + 手动组装 `.app` bundle（不依赖 Xcode 项目文件）

## 视觉系统

界面以 Tokyo Night 的蓝紫夜色和低干扰层级为基础；浅色模式使用 Tokyo Night Light 的对应色值，而不是简单反相。活动任务保持高对比，完成状态退居次要层级，蓝色只用于当前操作和选中状态，绿色与红色分别表达完成与删除。

待办与备份保存在本机 `~/Library/Application Support/WellSpent/`，窗口与外观偏好保存在本机 UserDefaults，不会上传到网络。

## 灵感来源

WellSpent 基于 [今天没白活](https://github.com/lijigang/JintianMeiBaihuo) 修改，并在此基础上重新设计了视觉主题、外观模式、应用名称、图标与项目结构。

## License

MIT © 2026 Howell · Scott · Stark
