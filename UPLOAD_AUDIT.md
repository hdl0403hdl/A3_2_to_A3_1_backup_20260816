# GitHub 上传审计

上传日期：2026-08-18（Asia/Shanghai）

## 已上传

- `A3_2_CONTEXT_INCREMENT.md`；
- 迁移 README、检查单、工具和审计元数据；
- GitHub Release `backup-20260816`：
  `A3_1_PORTABLE_UPDATE_20260816.tar.zst`；
- Release 资产大小：`1,587,215,633` bytes；
- GitHub 返回状态：`uploaded`；
- GitHub 返回 digest 与本地 SHA-256 一致：
  `90009fc55beb88b7a2ad494e7172716016ad91e129d5cdccbe4cf8dd8eaa3ccb`。

## 未上传

本机约 19 GiB 的工作目录未作为 Git 对象或 Release 资产整体上传，其中包括：

- `raw_snapshot/`；
- `target_before/`；
- 展开的 `deployment_payload/`；
- `a3_2_only_not_for_a3_1_install/`。

原因：这些内容远超普通 Git 文件/仓库的合理体积，同时原始快照的静态扫描
命中第三方示例 SSL 私钥和 Wi-Fi 密码参数/默认值。即使仓库是 private，也不
应未经清理直接上传原始设备快照。

完整 19 GiB 工作备份继续保留在源 Mac：

```text
/Users/hongdaliang/CODE/A3control/SYS_README/A3_2_to_A3_1_backup_20260816
```

Release 中的 portable archive 是原备份流程已经完成完整性测试和 SHA-256
验证的 A3_1 可安装迁移包；其范围和排除项见 `README.md`。
