# OfficeShiftScroll

Windows Microsoft 365 横向滚动插件原型，当前仅支持 **Excel 64 位**。Word、PowerPoint 尚未实现。

## 使用

从 [GitHub Releases](https://github.com/zvl-ab/OfficeShiftScroll/releases/latest) 下载 `OfficeShiftScroll-1.0.1-x64.zip`，完整解压后关闭 Excel，双击 `Install.cmd`。

- Shift+滚轮向上：向左滚动；向下：向右滚动。
- 普通滚轮、Ctrl 缩放、Ctrl+Shift、Alt 保持原生处理。
- `Check.cmd` 检查依赖、文件和进程；`Uninstall.cmd` 卸载。
- v1.0.1 修复已退出 Excel 条目阻塞安装的问题；真正运行的后台实例仍需关闭，脚本会显示 PID。

使用环境：Windows 10/11、Microsoft 365 Excel 64 位、.NET Framework 4.8、VSTO Runtime。安装后不需要 Visual Studio。开发签名可能需要在 Office 安装提示中确认信任；脚本不降低安全设置。

## 构建

1. 安装 Visual Studio 2022 或更新版本的 Office/VSTO 开发工具及 .NET Framework 4.8 开发包。
2. 打开 `ExcelShiftScroll.sln`，在项目“签名”设置中创建自己的测试证书，或将已有开发证书放在 `.local/ExcelShiftScroll_TemporaryKey.pfx` 并配置相应签名属性。私钥不要提交。
3. 使用 `Debug | x64`，F5 启动 Excel。本机已用 VS 2026 构建；VS 2022 尚未实机验证。
4. 在 PowerShell 运行 `packaging/Build-Release.ps1`，生成 `artifacts` 中的完整安装包、ZIP 和 SHA256 文件。

源码中不含发布二进制和签名私钥。`packaging` 中的 Install.cmd 需与构建生成的 App 和 PackageHashes.json 配套使用。

## 验证

```powershell
.\tests\Run-NativeSmokeTests.ps1
.\tests\Test-InstallerProcessCheck.ps1
```

核心横滚、普通滚轮、Ctrl 缩放、释放 Shift 恢复、Alt 已由用户确认。平滑感、复杂窗口、多屏/DPI、冻结窗格以及安装/卸载完整流程尚未全面验证。

## 实现与目录

通过 Excel UI 线程的 `WH_GETMESSAGE` 将符合条件的 `WM_MOUSEWHEEL` 原地改为 `WM_MOUSEHWHEEL`，清除该条消息的 `MK_SHIFT`，交还 Excel 处理。不模拟键盘、不发送 Alt、不使用全局低级 Hook、SendInput 或自制平滑动画。

窗口识别基于 XLMAIN/EXCEL7，目前只挂启动 UI 线程；其他产品和多 UI 线程覆盖需要后续实现。

- 根目录 C#、Properties：插件源码与 VSTO 工程。
- packaging：安装入口及发布脚本。
- tests：原生与安装脚本测试。
- .local：仅本机开发证书，Git 忽略。
- artifacts、bin、obj、.vs：发布产物及缓存，Git 忽略。

变更记录见 [CHANGELOG.md](CHANGELOG.md)。
