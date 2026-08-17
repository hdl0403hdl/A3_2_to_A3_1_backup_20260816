# A3_1 现场迁移检查单

## 安装前

- [ ] Mac 到 `192.168.46.251` 的 SSH 明确是 A3_1 HDU。
- [ ] 经 `192.168.46.251` 跳转的 `10.42.10.12` 明确是 A3_1 MDU。
- [ ] A3_1 HDU/MDU 时间、hostname、系统版本已记录。
- [ ] A3_1 `FDU_a3`、`FDU_pai` 命名没有被改成 `_2`。
- [ ] A3_1 HDU 外参已读取并备份。
- [ ] A3_1 MDU robot identity、EtherCAT 和 encoder 配置已读取并备份。
- [ ] HDU Planner/OptiTrack stack 已退出。
- [ ] MDU body-drive、发球、激励、移动与 zymotion 控制器均已退出。
- [ ] `tools/04_audit_a3_1.sh` 返回成功。
- [ ] `metadata/A3_2_COUPLING_SCAN.txt` 为空。

## 安装时

- [ ] 使用 `tools/05_install_a3_1.sh`，不手工 rsync `/agibot` 根目录。
- [ ] 记录安装时间戳。
- [ ] 确认生成 `target_before/<时间戳>/`。
- [ ] 确认远端生成 `/agibot/a3_1_update_backups/<时间戳>/`。
- [ ] 确认 active Planner 安装前后完全一致。
- [ ] 确认 V18 只新增到 registry，没有激活。

## 安装后静态验证

- [ ] V18 `planner_version.sh check` 通过。
- [ ] V18 `x_hit=0.20`、margin `0.150`、hysteresis `0.020`。
- [ ] MC1/MC2 symlink 正确。
- [ ] MC1/MC2 shell/Python/test 全部通过。
- [ ] MC1/MC2 使用 A3_1 外参。
- [ ] A3_1 identity、外参、网卡和 active Planner 未改变。
- [ ] 没有控制器因验证动作而启动。

## 后续首次运行

- [ ] 由现场人员重新确认吊架、急停、限速和控制权唯一性。
- [ ] 先启动原 A3_1 Planner/策略做基线，不先激活 V18。
- [ ] 单独选择 V18 时记录新 session，确认 Planner 输出和刚体名仍为 A3_1。
- [ ] MC1/MC2 首次只做最小安全验证，不与其他控制器并发。
- [ ] 发生身份、外参、网卡或控制权异常时立即退出，不现场覆盖配置。

## 回滚

- [ ] 所有 Planner/控制器已退出。
- [ ] 使用对应安装时间戳执行 `tools/07_rollback_a3_1.sh`。
- [ ] 复核 A3_1 identity、外参、active Planner 和原入口 hash。
- [ ] 保留 `/agibot/a3_1_failed_update_<时间戳>/` 供事后分析。
