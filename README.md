# OfficeShiftScroll

## 作用

Windows 版 Microsoft 365 Office 插件原型。

在支持的 Office 工作区中，将 `Shift + 垂直滚轮` 转换为原生横向滚动：

- 向上滚轮向左滚动，向下滚轮向右滚动。
- 普通滚轮继续执行原生纵向滚动。
- Ctrl+滚轮、Ctrl+Shift+滚轮、Alt 和其他 Office 操作保持原样。
- 不模拟键盘，不发送 Alt，不使用 SendKeys，不实现自定义平滑动画。

当前版本已在 Excel Microsoft 365 64 位上实测通过；工程仍是 Excel VSTO 原型，后续扩展到 Word、PowerPoint 等 Office 产品。

## 实现方式

插件在 Office UI 线程的 `WH_GETMESSAGE` 消息处理中检查鼠标滚轮消息。满足工作区、前台窗口和 Shift 条件时，将 `WM_MOUSEWHEEL` 原地改为 `WM_MOUSEHWHEEL`，并清除该条消息的 `MK_SHIFT` 标志，再交回 Office 原生处理流程。

这种方式不注入键盘事件，不调用 `SendInput`，不维护定时器或滚动状态，因此横向滚动由 Office 自己处理。当前窗口识别使用 Excel 的 `XLMAIN` 和 `EXCEL7` 类名，Office 全产品兼容需要后续抽象窗口识别和按产品验证。

项目目标：Windows 10/11、Office 365 64 位、Visual Studio 2022、C#、.NET Framework 4.8、x64。