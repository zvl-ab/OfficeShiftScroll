ExcelShiftScroll 快速使用版（queue-hwheel-v3 / Release x64）

首次使用
1. 保存工作，关闭所有 Excel 窗口，并结束 Visual Studio 的 F5 调试。
2. 双击 Install.cmd。
3. 在 Office 安装窗口中确认安装 ExcelShiftScroll。
4. 正常打开 Excel，在工作表区域按住 Shift 并滚动鼠标滚轮。

以后使用
直接打开 Excel 即可，不需要运行 Visual Studio，不需要反复安装。
向上滚轮：向左滚动；向下滚轮：向右滚动。
松开 Shift 后恢复普通纵向滚动。Ctrl 缩放和 Alt 保持原生行为。
没有 Ribbon 按钮或设置窗口。

卸载
先关闭 Excel，再双击 Uninstall.cmd。也可使用 Windows 已安装的应用/程序和功能卸载 ExcelShiftScroll。
请保留这整个文件夹，便于检查、重装与卸载；不要只复制 DLL。

文件
Install.cmd   首次安装（当前 Windows 用户）
Uninstall.cmd 卸载插件
Check.cmd     只检查依赖和文件完整性，不安装、不修改设置
App           Office/VSTO 正式发布文件，包含签名清单和运行库
Manage.ps1    上述入口使用的管理脚本

环境
Windows 10/11、Microsoft 365 Excel 64 位、.NET Framework 4.8、VSTO Runtime。
使用此包不需要安装 Visual Studio。本机已具备运行环境。
其他电脑缺少 VSTO Runtime 时，请从微软安装：
https://www.microsoft.com/en-us/download/details.aspx?id=48217

常见情况
- 提示 Excel 正在运行：保存并关闭所有 Excel；脚本不会强制结束进程。
- 发布者/信任提示：本包使用 ExcelShiftScroll Development 开发证书，由 Office 正常显示提示。核对名称后决定是否安装；脚本不会导入根证书或关闭安全检查。
- 如果系统明确拒绝信任安装，保留错误详情排查，不要降低 Office 安全设置。本包适用于当前机器快速使用，尚未验证其他电脑的证书信任。
- 提示另一位置已安装同名插件：先卸载旧的 ExcelShiftScroll，再安装此包；不要卸载其他插件。
- 安装成功但无效果：在 Excel 文件 → 选项 → 加载项 → 管理 COM 加载项中检查 ExcelShiftScroll 是否勾选。
- 再次 F5 调试可能与已安装版本的注册发生冲突。建议先卸载快速版，再调试；调试结束后重新安装快速版。
- 双击脚本只会对本次 PowerShell 进程设置执行策略，不永久更改系统策略。

验证状态
核心方案已由用户实测：Shift 横滚、Ctrl 缩放、普通滚轮、释放 Shift 恢复、Alt 正常。
此包使用相同源码的 Release 构建。发布、文件完整性和依赖检查已完成；尚未执行此包的安装/卸载端到端测试。
未加入自制平滑算法、键盘模拟、全局低级 Hook 或自动更新。
