# WellSpent

> 把时间留给值得的事。

我想要的待办工具很简单：随手记，做完勾掉，然后继续做正事。WellSpent 是一扇留在 macOS 桌面角落的小窗，不打算把一件待办包装成一套工作流。

<p align="center">
  <img src="attachments/screenshot-v2.png" alt="WellSpent 界面预览" width="380">
</p>

## 下载

从 [GitHub Releases](https://github.com/Howell-Shinji/WellSpent/releases/latest) 下载最新 DMG，把 `WellSpent.app` 拖进「应用程序」。支持 macOS 13 及以上。

应用尚未签名或公证。首次启动如果被 macOS 拦截，可在 Finder 中右键点击 `WellSpent.app`，选择「打开」并确认。

## 怎么用

- 输入待办，按 `Enter` 添加。
- 点击圆圈标记完成或恢复未完成；已完成项收在下方，可以折叠。标题只统计剩余项。
- 双击文字编辑；`Enter` 保存，`Esc` 取消。长任务可以展开。
- 点击垃圾桶删除；5 秒内可点击「撤销」。连续删除会重新计时。
- 点击齿轮选择跟随系统、浅色或深色模式，也可调整置顶和透明度（30%–100%）。

## 几个设计决定

- **少打扰。** 窗口默认置顶，也能关闭置顶；位置和尺寸会记住。界面采用 Tokyo Night 配色，浅色与深色分别设计，不是简单反相。
- **数据留在本机。** 待办保存在 `~/Library/Application Support/WellSpent/`。没有账号、云同步或网络请求。
- **出错要说清楚。** 每次修改立即保存，并保留上一份有效备份。读取失败时不会把原文件当成空列表覆盖；保存失败会提示重试。

## 当前版本

v2.0.1 修复了完成任务后勾选状态可能显示错误的问题，并把删除撤销提示缩短为 5 秒。v2 还加入了任务编辑、备份恢复、窗口位置记忆和置顶开关。

## 从源码构建

需要 macOS 13+ 和 Xcode Command Line Tools。在仓库根目录运行：

```bash
bash ./WellSpent/scripts/test.sh
./WellSpent/scripts/build.sh
open "WellSpent/build/WellSpent.app"
```

需要 DMG 时，再运行 `./WellSpent/scripts/package-dmg.sh`。项目使用 SwiftUI + AppKit，不依赖第三方库；构建脚本直接调用 `swiftc`。

## 灵感来源

WellSpent 基于 [今天没白活](https://github.com/lijigang/JintianMeiBaihuo) 修改。视觉主题、外观模式、名称、图标与项目结构在此基础上重新设计。

## 许可

[MIT](LICENSE) © 2026 Howell · Scott · Stark
