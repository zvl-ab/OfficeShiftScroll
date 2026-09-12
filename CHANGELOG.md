# 更新日志

## 未发布

- 添加 MIT 许可证及 README 开源声明；后续打包自动包含 LICENSE。

## [1.0.1] - 2026-09-12

### 修复

- 安装和卸载检查忽略 `HasExited=True` 的已终止 Excel 条目，避免没有打开 Excel 却一直要求退出。
- 真正运行的 Excel 显示 PID、启动时间和主窗口状态；状态未知时仍保守阻止安装，不自动结束进程。
- Check.cmd 同时检查进程阻塞，并用退出码 2 区分该情况。

### 工程整理

- 将安装入口、说明和管理脚本纳入 packaging，增加可重复执行的 Release 打包脚本。
- 开发证书移入 Git 忽略的 .local，发布文件统一输出到 artifacts。
- 清理历史临时产物，补充换机构建说明与文件换行规则。
- 程序集和发布清单版本更新为 1.0.1.0，横向滚动逻辑不变。

### 验证

- 安装进程过滤：已退出、运行中与已退出混合、状态未知、空列表四种场景。
- x64 消息结构、原生组合键放行与 10 次 Hook 生命周期测试。
- Release 构建、签名发布、文件哈希与本机 Check 模式。
- 未将安装/卸载完整交互流程或所有 Office 版本兼容性标记为通过。

## [1.0.0] - 2026-09-11

- 首个 Excel Microsoft 365 64 位可用版本。
- 在 Excel UI 消息队列内将 Shift+垂直滚轮转换为横向滚轮，并清除该消息的 Shift 标志。
- 用户确认核心横滚、普通滚轮、Ctrl 缩放、释放 Shift 恢复及 Alt 正常。
- 提供 VSTO 安装包和安装、卸载、检查入口。

[1.0.1]: https://github.com/zvl-ab/OfficeShiftScroll/releases/tag/v1.0.1
[1.0.0]: https://github.com/zvl-ab/OfficeShiftScroll/releases/tag/v1.0.0
