OfficeShiftScroll 1.0.1 快速使用版

1. 保存工作并关闭 Excel。
2. 解压完整文件夹，双击 Install.cmd，按 Office 安装提示完成安装。
3. 正常打开 Excel，在工作表中使用 Shift+鼠标滚轮横向滚动。

向上向左，向下向右；普通滚轮、Ctrl 缩放和 Alt 保持原生行为。
不需要 Visual Studio。当前支持 Windows 10/11、Microsoft 365 Excel 64 位、.NET Framework 4.8 和 VSTO Runtime。

Check.cmd：检查依赖、发布文件完整性及 Excel 进程；0 表示通过，2 表示有 Excel 进程阻塞，1 表示检查失败。
Uninstall.cmd：关闭 Excel 后运行，卸载当前插件。

安装提示有 Excel 进程但没有窗口时，查看列出的 PID、启动时间与窗口状态。真正运行的后台 Excel 仍需先结束；已退出的进程不再阻塞。脚本不会自动终止进程。强制结束可能丢失未保存数据，请先保存工作。

使用开发签名证书，Office 可能显示发布者信任提示。脚本不修改证书信任或 Office 安全设置。
VSTO Runtime：https://www.microsoft.com/en-us/download/details.aspx?id=48217

升级：先关闭 Excel，再运行新版本 Install.cmd；如 Office 提示另一位置已安装同名解决方案，先从 Windows 已安装应用卸载旧 ExcelShiftScroll，再安装新包。

v1.0.1 修复安装进程误判，插件横向滚动逻辑不变。安装/卸载完整交互流程仍需在目标机器验证。
