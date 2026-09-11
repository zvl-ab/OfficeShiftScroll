# ExcelShiftScroll

Windows 10/11，Excel Microsoft 365 64 位，C# / .NET Framework 4.8 VSTO Add-in。

## 获取源码

此仓库包含源码、测试和 Output 中的管理脚本。开发签名私钥、构建产物以及 Output/App 发布包不提交到 Git。克隆源码后需在 Visual Studio 项目“签名”中创建自己的测试证书，再构建；仅下载源码时不能直接运行 Output/Install.cmd，需先生成完整发布包。
## 当前版本：queue-hwheel-v3（核心横滚已实机确认）

Excel UI 线程的 WH_GETMESSAGE → 仅处理 PM_REMOVE → 将符合条件的 WM_MOUSEWHEEL 原地改为 WM_MOUSEHWHEEL，并清除这条鼠标消息的 MK_SHIFT。

不修改实际键盘状态，不模拟 Ctrl、Shift、Alt，不使用 SendKeys。没有全局低级 Hook、SendInput、额外线程、计时器、平滑算法或重复投递消息。调用 CallNextHookEx 保留其他 Hook 链。

用户于 2026-09-11 确认第三版 Shift+滚轮成功。原生横向消息交给 Excel 消息处理流程；平滑感与完整回归验收尚未逐项确认。消息里的 Shift 标志与物理 Shift 状态是两回事，本实现仅改写前者。

## 接管范围

- WM_MOUSEWHEEL 的按键/鼠标按钮位必须恰好为 MK_SHIFT。
- Ctrl、Alt、Win 处于按下状态时不转换；普通 Wheel、Ctrl+Wheel、Ctrl+Shift+Wheel 原样传递。
- 只检查本插件所在 Excel 进程，前台且启用的 XLMAIN。
- 鼠标命中位置与消息接收窗口必须属于同一 EXCEL7 工作表区域。
- 方向：向上 → 向左；向下 → 向右；保留小于 120 的 delta。
- delta 为 0 或 -32768 时放行，后者取反无法装入消息的有符号 16 位 delta。

EXCEL7 是 Excel 窗口实现细节。复杂子控件、编辑模式、多屏/DPI、冻结窗格尚未全面验证。只挂启动 UI 线程；若另一个工作簿使用不同 UI 线程，需后续增加按线程管理，当前不会覆盖它。

## 构建

1. Visual Studio 2022 或更新版本，安装 Office/SharePoint 开发（VSTO）和 .NET Framework 4.8 开发包。
2. 打开 ExcelShiftScroll.sln，选择 Debug | x64。
3. 关闭旧调试 Excel，F5 启动新实例；运行中的 Excel 不会热加载新版 DLL。
4. 新建空白工作簿，将鼠标放到表格中央，Shift+向下滚动测试向右，再向上测试向左。

本机 VS 2026 18.10 已构建通过；VS 2022 未实机验证。项目没有硬编码 VS 18，缺少 Office targets 时明确报错。现有 TemporaryKey.pfx 是开发签名，换机缺失时在项目签名设置中创建测试证书，不用于正式发布。

## 实际排查证据

2026-09-11，本机 Excel 文件版本 16.0.19127.20302。

1. 旧 PostMessage 版本：Hook 安装、Shift 检测、EXCEL7 命中、消息入队均成功，用户反馈无滚动。入队不等于 Excel 处理。
2. 用 computer-use 发不带 Shift 的纯横向鼠标输入，空白表从 A 列滚到 M 列，行仍从 1 开始，无 KeyTips。此项没有验证 Shift 转换或动态平滑感。
3. 第一版 SendInput：用户确认失败；PID 7112 记录 send-input=True。
4. 第二版延后 SendInput：用户仍确认失败。PID 31776 的 UI 队列记录 msg=20E、keys=4、delta=120、extra=45535348，证明带 Shift 的横向消息实际到达 Excel，而非仅发送成功。没有看到完整低级回调/发送完成记录，不能排除该路线还有阻塞问题。
5. 第三版转为 UI 队列原地转换，移除发送链路，并将鼠标消息的 keys 从 4 变为 0。用户确认成功；PID 19924 日志记录了 delta=120 和 -120 的 queue-convert。由于同时改变了消息路径和 Shift 标志，不能单独断言清除标志是唯一根因。

## 诊断与检查

日志：%TEMP%\ExcelShiftScroll.diagnostic.log，包含 PID、时间。

- addin-start path=queue-hwheel-v3：确认第三版加载。
- queue-hook-installed：UI 线程 Hook 安装成功。
- queue-wheel：读取到的原生消息（每次加载最多记录 30 条）。
- queue-convert ... keys-before=4 keys-after=0：成功改写（最多记录 20 条）。
- queue-hook-uninstalled success=True：卸载完成。

日志异步尽力写入；Excel 退出时末尾记录可能未落盘，不能仅据此判断泄漏。

运行 tests\Run-NativeSmokeTests.ps1。已通过：x64 MSG 布局、普通/Ctrl/鼠标按钮组合不改写、10 次线程内 Hook 安装/重复启动/重复卸载、卸载后拒绝重启。这不能替代 Excel 横向滚动实测。

人工验收：核心 Shift+滚轮横向滚动已确认。仍待逐项确认普通滚轮平滑感、横滚方向/无纵向移动/无 KeyTips、Ctrl 缩放、Ctrl+Shift 原生横滚、释放 Shift、Ribbon/公式栏/菜单/对话框排除、其他软件不受影响、正常退出。

如果确认第三版发生 queue-convert 但依然不滚动，不能宣称已实现原生平滑横滚；应停止这条路径并分析 Excel 对横向消息与键盘状态的额外依赖。WM_HSCROLL 或 ScrollColumn 是可讨论的降级方案，但不保证平滑，不在本版自动加入。

参考：[GetMsgProc](https://learn.microsoft.com/en-us/windows/win32/winmsg/getmsgproc)、[WM_MOUSEHWHEEL](https://learn.microsoft.com/en-us/windows/win32/inputdev/wm-mousehwheel)、[SendInput](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput)。
