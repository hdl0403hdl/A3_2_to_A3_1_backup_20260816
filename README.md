# A3_2 → Mac 备份与 A3_1 安全迁移包

生成日期：2026-08-16（Asia/Shanghai）

## 1. 当前结论

本目录已经完成 A3_2 的项目级全量备份，并从原始快照构建了一个面向 A3_1 的独立迁移 payload。

- A3_2 HDU：`agi@192.168.47.31`
- A3_2 MDU：`agi@10.42.10.12`，经 A3_2 HDU 跳转
- A3_1 HDU：`agi@192.168.46.251`
- A3_1 MDU：`agi@10.42.10.12`，必须经 A3_1 HDU 跳转
- 原始快照：HDU2 约 4.4 GiB，MDU2 约 5.9 GiB
- 原始清单：HDU2 7,954 个条目，MDU2 28,572 个条目
- 普通文件 SHA-256：HDU2 6,582 个，MDU2 23,867 个
- 远端到 Mac 的逐文件内容校验：PASS
- A3_1 payload 本地静态验证：PASS
- 可搬运安装包：`A3_1_PORTABLE_UPDATE_20260816.tar.zst`，约 1.5 GiB
- 安装包 SHA-256：见同目录 `PACKAGE_SHA256.txt`
- A3_1 实际安装：尚未执行
- 未执行原因：A3_1 HDU `192.168.46.251:22` 当前连接超时
- 本次没有启动、停止或切换任何 Planner/控制器，也没有进入 POLICY

当前状态以 [A3_1_DEPLOYMENT_STATUS.txt](metadata/A3_1_DEPLOYMENT_STATUS.txt) 为准。

## 2. 三层内容

### 2.1 A3_2 原始项目快照

路径：

- `raw_snapshot/HDU2/agibot/`
- `raw_snapshot/MDU2/agibot/`

这是排除录制和系统运行态后的 A3_2 `/agibot` 项目快照。它用于追溯、比较和重新构建迁移包，不应直接整体覆盖 A3_1。

排除项包括：

- `data/`、`records/`、`records_hdu/`、`joint_records/`、`bag/`；
- 运行日志、cache、core dump；
- `.ota/` 中受保护的系统 OTA/NetworkManager 密钥副本；
- `sys/` 中的实时 Unix socket；
- 历史迁移副本和重复 `*.a3_2_old_*`/`*.backup_*` 树。

完整规则见 [EXCLUSIONS.tsv](metadata/EXCLUSIONS.tsv)。这些排除项不属于本次 Planner/MDU 运行代码迁移范围。

### 2.2 A3_1 可安装 payload

路径：

- `deployment_payload/HDU1/agibot/`
- `deployment_payload/MDU1/agibot/`

它不是 A3_2 的逐字镜像，而是经过机器身份隔离后的 A3_1 安装源：

- 保留 Planner V18、当前 Planner 工具和代码环境；
- 保留 MDU ONNX 部署、MC1/MC2 及其依赖；
- 不携带 A3_2 的 robot identity、Motive 刚体名、HDU 网卡/IP、active Planner；
- 不覆盖 A3_1 的 `FDU_a3 → pelvis_link` 标定；
- MC1/MC2 使用 A3_1 已审计外参；
- 不携带任何录制；
- active runtime 的 A3_2 耦合扫描结果为 0。

### 2.3 仅 A3_2 保留、禁止安装到 A3_1

路径：`a3_2_only_not_for_a3_1_install/`

`hitter_a3_stage2_v3_hdu` 和 `hitter_a3_stage2_v3_model52500_110` 明确硬编码了 `FDU_a3_2`、`FDU_pai_2` 与 `robot_id=a3_2`。它们已完整保留，但从 A3_1 payload 隔离，避免错误覆盖。

### 2.4 可搬运压缩包

`A3_1_PORTABLE_UPDATE_20260816.tar.zst` 包含 README、迁移检查单、A3_1 payload、工具和审计元数据，不包含 10 GiB 原始快照，也不包含 A3_2 专属 Stage‑2 链。zstd 完整性测试与外置 `PACKAGE_SHA256.txt` 检查均已通过。

## 3. Planner V18

源路径：

`raw_snapshot/HDU2/agibot/b17996_mdu/planner_versions/v18_lateral_margin_return118/`

A3_1 payload 路径：

`deployment_payload/HDU1/agibot/b17996_mdu/planner_versions/v18_lateral_margin_return118/`

关键配置：

- `x_hit = 0.20 m`
- 横向边界内缩 `0.150 m`
- 边界 hysteresis `0.020 m`
- 标准本侧到球网区间只接受恰好 1 次 bounce
- 来球过网高度门限保持 V14/V18 既有规则
- return118 法向量和 V10 风格 revision gate 保持不变

迁移脚本只把 V18 注册为菜单 18；不会修改 `active_planner_version`。因此安装完成后，A3_1 原来正在使用的 Planner 版本仍保持不变。

## 4. MC1_XL1 / MC2_XL1

顶层入口：

- `/agibot/MC1_XL1.sh -> /agibot/mc1_xl1/MC1_XL1.sh`
- `/agibot/MC2_XL1.sh -> /agibot/mc2_xl1/MC2_XL1.sh`

主要依赖：

- `/agibot/bounce_pour_hope_real_v3_quick`
- `/agibot/b17996_mdu_726_return118_model23198`
- `/agibot/b17996_mdu_726_return118_model23198/run_live_record_xl118_1.sh`

A3_1 外参写入两个 package 的 `site.env`：

```text
XYZ  = 0.017662585,-0.003902495,0.152126430
WXYZ = 0.99218121843,0.00382893327,0.05297072783,-0.11294189240
```

这与 A3_2 的外参不同。安装器不会复制 A3_2 的 site activation 文件到 A3_1。

## 5. 明确保护的 A3_1 状态

安装过程禁止覆盖：

- A3_1 HDU robot identity；
- A3_1 `FDU_a3 → pelvis_link` 平移和旋转外参；
- A3_1 active Planner；
- A3_1 Planner registry 中除新增 V18 以外的项目；
- A3_1 NetworkManager、接口名、machine-id、SSH host key；
- A3_1 MDU EtherCAT、encoder zero、固件和 robot identity；
- 所有录制、日志和 bag。

精确路径见 [A3_1_PROTECTED_PATHS.txt](metadata/A3_1_PROTECTED_PATHS.txt)。

## 6. A3_1 恢复在线后的安装流程

以下命令在 Mac 执行。先确认两个 SSH 链路分别指向 A3_1，而不是 A3_2：

```bash
ssh -o BatchMode=yes agi@192.168.46.251 'hostname; date -Is'
ssh -o BatchMode=yes -J agi@192.168.46.251 agi@10.42.10.12 'hostname; date -Is'
```

进入本目录：

```bash
cd /Users/hongdaliang/CODE/A3control/SYS_README/A3_2_to_A3_1_backup_20260816
```

第一步，只读审计：

```bash
tools/04_audit_a3_1.sh
```

第二步，检查 `metadata/A3_1_PREFLIGHT_*.txt`，确认 A3_1 身份、外参、磁盘空间和进程状态正确。

第三步，执行受确认字符串保护的安装：

```bash
A3_1_INSTALL_CONFIRM=INSTALL_A3_2_PORTABLE_UPDATES_TO_A3_1 \
  tools/05_install_a3_1.sh
```

安装器会：

1. 再次拒绝在 HDU Planner 或 MDU 控制器运行时安装；
2. 将目标现状保存到本机 `target_before/<时间戳>/`；
3. 在 A3_1 `/agibot/a3_1_update_backups/<时间戳>/` 保存被替换文件；
4. 只同步 portable payload；
5. 合并 V18 registry，不切换 active Planner；
6. 执行静态验证；
7. 不启动任何控制程序。

## 7. 验证与回滚

安装后的静态复核：

```bash
tools/06_verify_a3_1.sh <安装时间戳>
```

如需回滚：

```bash
A3_1_ROLLBACK_CONFIRM=ROLLBACK_A3_1_UPDATE \
  tools/07_rollback_a3_1.sh <安装时间戳>
```

回滚同样拒绝在控制进程运行时执行。安装前不存在的新目录不会被删除，而会移动到 A3_1 的 `/agibot/a3_1_failed_update_<时间戳>/`，便于恢复和审计。

## 8. 备份刷新与复现

重新读取 A3_2 并刷新 Mac 原始快照：

```bash
tools/02_pull_backup.sh
tools/08_verify_snapshot.sh
```

从原始快照重新生成 A3_1 payload：

```bash
tools/03_build_a3_1_payload.sh
```

注意：刷新会反映 A3_2 当时的最新项目文件。刷新后必须重新阅读 coupling scan、重跑本地验证并更新 package checksum，不能直接沿用旧的审计结论。

## 9. 关键审计文件

- [SOURCE_PATHS.tsv](metadata/SOURCE_PATHS.tsv)：远端来源与本机落点；
- [SNAPSHOT_VERIFY_RESULT.txt](metadata/SNAPSHOT_VERIFY_RESULT.txt)：远端/本地内容复核；
- [HDU2_FILE_MANIFEST.tsv](metadata/HDU2_FILE_MANIFEST.tsv)：HDU2 文件级清单；
- [MDU2_FILE_MANIFEST.tsv](metadata/MDU2_FILE_MANIFEST.tsv)：MDU2 文件级清单；
- [SHA256SUMS.HDU2](metadata/SHA256SUMS.HDU2)：HDU2 普通文件哈希；
- [SHA256SUMS.MDU2](metadata/SHA256SUMS.MDU2)：MDU2 普通文件哈希；
- [SHA256SUMS.HDU1_PAYLOAD](metadata/SHA256SUMS.HDU1_PAYLOAD)：HDU1 payload 哈希；
- [SHA256SUMS.MDU1_PAYLOAD](metadata/SHA256SUMS.MDU1_PAYLOAD)：MDU1 payload 哈希；
- [LOCAL_PAYLOAD_VERIFY.txt](metadata/LOCAL_PAYLOAD_VERIFY.txt)：本地 V18/MC 静态测试；
- [A3_2_COUPLING_SCAN.txt](metadata/A3_2_COUPLING_SCAN.txt)：A3_1 payload 的 A3_2 运行耦合扫描；
- [MIGRATION_CHECKLIST.md](MIGRATION_CHECKLIST.md)：现场执行检查单。

## 10. 安全边界

本包不是“整盘克隆”。A3_1 与 A3_2 的硬件标定、刚体名、网卡、IP、robot identity 和部分实验链不同，必须保持机器专属。任何正式测试都应在安装完成、静态验证通过后，由现场人员按正常安全流程独立启动；本备份流程不会替用户进入 `s/r/m` 或发送关节命令。
