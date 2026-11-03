# WellSpent

> 把时间留给值得的事。

我想要的待办工具很简单：随手记，做完勾掉，然后继续做正事。WellSpent 是一扇留在 macOS 桌面角落的小窗，不打算把一件待办包装成一套工作流。

<p align="center">
  <img src="attachments/compact-light.png" alt="WellSpent Tokyo Night 浅色紧凑视图（示例任务）" width="300">
  <img src="attachments/compact-dark.png" alt="WellSpent Tokyo Night 深色紧凑视图（示例任务）" width="300">
</p>

<details>
<summary>完整列表</summary>
<p align="center">
  <img src="attachments/screenshot-v2.1.png" alt="Tokyo Night 浅色完整列表（示例任务）" width="320">
  <img src="attachments/screenshot-v2.1-dark.png" alt="Tokyo Night 深色完整列表（示例任务）" width="320">
</p>
</details>

## 下载

从 [GitHub Releases](https://github.com/Howell-Shinji/WellSpent/releases/latest) 下载最新 DMG，把 `WellSpent.app` 拖进「应用程序」。目前支持 Apple Silicon Mac（macOS 13 及以上），不支持 Intel Mac。

应用尚未签名或公证。首次启动如果被 macOS 拦截，可在 Finder 中右键点击 `WellSpent.app`，选择「打开」并确认。

## 怎么用

- 默认使用紧凑视图：只显示按优先级排列的前三条未完成待办，勾掉后下一条自动补上。窗口约 `300 × 202`，文字保持清晰，底色不透明。
- 点击右上角 `+` 输入待办，按 `Enter` 添加；展开后的输入框与之前一样。
- 点击右上角展开图标或底部「查看全部」打开完整列表；再次点击可收起。两种视图分别记住位置和尺寸，重启后保留选择。
- 点击圆圈标记完成或恢复未完成；已完成项收在下方，可以折叠。标题只统计剩余项。
- 点击任务右侧的旗帜设置优先级：暖金色为高、中性灰为普通、冷蓝色为低；悬停或打开菜单可查看等级说明。未完成项按等级排列，同级保持原有顺序。旧任务默认为普通。
- 紧凑视图的长任务会截断，悬停可查看全文；双击会展开完整列表并进入编辑。完整列表中双击文字编辑；`Enter` 保存，`Esc` 取消。长任务可以展开。
- 紧凑视图中右键删除，完整列表中点击垃圾桶删除；5 秒内可点击「撤销」。连续删除会重新计时，一次撤销可恢复这段时间内删除的全部任务。
- 点击齿轮选择跟随系统、浅色或深色模式，也可调整置顶。完整列表可调整窗口透明度（30%–100%）；紧凑视图始终不透明。

## 几个设计决定

- **少打扰。** 窗口默认置顶，也能关闭置顶；位置和尺寸会记住。界面采用 Tokyo Night 配色，浅色与深色分别设计，不是简单反相。
- **数据留在本机。** 待办保存在 `~/Library/Application Support/WellSpent/`。没有账号、云同步或网络请求。
- **出错要说清楚。** 每次修改立即保存，并保留上一份有效备份。读取失败时不会把原文件当成空列表覆盖；保存失败会提示重试。

## 当前版本

v2.2.0 加入紧凑视图，用更小的窗口保留最需要看到的待办。撤掉 v2.1.3 的磨砂与背景叠层，完整列表恢复原来的外观。优先级、撤销与数据保存功能继续保留。

## 从源码构建

需要 Apple Silicon Mac、macOS 13+ 和 Xcode Command Line Tools。在仓库根目录运行：

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
