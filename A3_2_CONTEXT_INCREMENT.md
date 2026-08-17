# 第二台 A3 上下文增量与信息共享

Last verified: **2026-08-13 (Asia/Shanghai)**  
Document role: 第二台 A3 的跨会话事实入口；用于交给其他 Codex/分析人员继续工作。  
Truth rule: 若本文与旧计划冲突，以本文引用的较新实测审计为准；远端当前状态仍应先做只读复核。

## 0. 可直接复制给其他 Codex 的上下文增量

```text
【A3_2 / 第二台A3上下文增量，已核实至 2026-08-13】

开始任何第二台 A3 工作前，先阅读：
/Users/hongdaliang/CODE/A3control/SYS_README/A3_2_CONTEXT_INCREMENT.md

固定身份与网络：
- A3_1：HDU=agi@192.168.46.251；MDU=agi@10.42.10.12，必须经 -J agi@192.168.46.251。
- A3_2：HDU=agi@192.168.47.31；MDU=agi@10.42.10.12，必须经 -J agi@192.168.47.31。
- 两个 10.42.10.12 属于两套不同机器人内部网。缺少或用错 ProxyJump 会访问错误机器人。
- 用户约定两台控制链轮流使用，目前没有依靠 ROS_DOMAIN_ID 实现双机控制隔离。

A3_2 HDU合同：
- robot_id=a3_2；robot_label=第二台A3。
- base rigid body=FDU_a3_2，topic=/FDU_a3_2/pose。
- racket rigid body=FDU_pai_2，topic=/FDU_pai_2/pose。
- rigid ball 名称严格为 Ball（大小写敏感）；球可以暂时不出现，但 base pose 是栈就绪条件。
- 2026-08-12 快照中的活动 Planner=v12_return118_v10_revision。
- 专用入口=/agibot/b17996_mdu/run_hdu_stack_a3_2.sh。
- Motive server=192.168.100.111；计划中的 HDU2 Motive 地址=192.168.100.253/24；Mac monitor=192.168.47.249。

A3_2 MDU已迁移：
- 8套正式 runtime：3套114D部署和5套118D部署；31个ONNX合同已解析，26个114D→31D、5个118D→31D。
- 已有 /agibot/A3control_moveAndfaqiu.sh、/agibot/hope_pdstand_serve_player/player.sh、
  /agibot/faqiuS_2_xl6.sh、/agibot/激励录制播放/player.sh 等工具。
- 迁移时的静态校验、ONNX CPU推理、runtime self-test、无输出probe和合成HDU→HP14→MDU→ONNX链路均通过。
- 迁移验证没有进入ONNX POLICY。之后已有A3_2确定性PD-stand/发球播放器实机记录，
  但这不能当作114D/118D POLICY已经验收。

Mac监控和归档：
- live：http://127.0.0.1:8765/?robot_id=a3_2
- replay：http://127.0.0.1:8765/hit-replay.html?robot_id=a3_2&session=<SESSION>&robot=urdf
- archive：archive_recording.sh --robot a3_2 --latest 40
- A3_2的recording/analysis/sync/replay/archive状态按robot_id隔离；旧URL默认a3_1。

必须保留的状态边界：
- TEMPORARY：FDU_a3_2→pelvis_link仍使用A3_1外参作为初始值，尚未完成A3_2独立标定。
- BLOCKED/WARN：2026-08-12审计时HDU2没有识别到Motive USB网卡，.253未绑定，
  FDU_a3_2/FDU_pai_2/Ball实物流和第二台外参未完成验收。操作前必须重新检查，不可假设仍然缺失或已经解决。
- DRIFT：A3_1后续五套118D配置已改为publish_hz=200，A3_2迁移快照仍为500；
  A3_1已有faqiuS_2_xl6_next，A3_2仍是较早的直接model25400交接。未经决定不要自动同步。

real2real已知结论：
- 两台上层500Hz控制器、serve_player配置、31关节Kp/Kd和24项HAL电机合同字段相同。
- 内核构建、HAL二进制/动态库、调度/QoS、debug/IMU通道和hal_thermal运行状态不同。
- 对比记录中A3_1电池约57V、39–41°C；A3_2约62.6V、71°C。
- 已观察到关节响应和一次A3_2 tilt safety abort差异，但数据不足以把gap归因于电机本体。
- HAL fault event ID只能原样记录；没有《洞庭A3故障事件定义》时禁止猜测含义。

安全与操作规则：
- 未经用户明确授权，不运行控制入口，不按 p/s/r/m/y/b，不切换MC，不发布关节命令。
- 所有MDU2命令显式使用 -J agi@192.168.47.31；部署只允许HDU1→HDU2、MDU1→MDU2，禁止交叉复制。
- 不复制machine-id、SSH host key、NetworkManager UUID/MAC绑定、EtherCAT硬件配置、编码器零位或厂商固件。
- A3_2外参未达到position p95≤10mm、orientation p95≤3°前，不进入POLICY。
- A3_1的新变化不能直接覆盖A3_2；先列差异、确认运行合同，再单独迁移和回滚。
```

## 1. 状态标签

- **VERIFIED**：已有文件哈希、静态检查、无输出链路或录制数据支持。
- **TEMPORARY**：只是可启动初值，不能作为第二台标定结论。
- **BLOCKED**：上次审计明确缺少现场条件；使用前必须重新检查当前状态。
- **DRIFT**：A3_1 在迁移快照之后发生变化，A3_2 尚未跟随。
- **UNKNOWN**：现有资料不足，禁止按经验补全或下因果结论。

## 2. 双机身份和寻址（VERIFIED）

### A3_1 / 第一台A3

```text
HDU SSH        agi@192.168.46.251
MDU SSH        agi@10.42.10.12
MDU ProxyJump  agi@192.168.46.251
Base           FDU_a3
Racket         FDU_pai
Ball           Ball
```

### A3_2 / 第二台A3

```text
HDU SSH        agi@192.168.47.31
MDU SSH        agi@10.42.10.12
MDU ProxyJump  agi@192.168.47.31
Base           FDU_a3_2
Racket         FDU_pai_2
Ball           Ball
robot_id       a3_2
robot_label    第二台A3
```

正确的 MDU2 只读连接模板：

```bash
ssh -o BatchMode=yes -J agi@192.168.47.31 agi@10.42.10.12 '<只读命令>'
```

两个 MDU 地址相同但物理目标不同，不能依赖 shell 历史或省略跳板。用户此前选择两台轮流运行，不应推断为允许同时控制。

## 3. HDU2、Motive 和 Planner

### 已验证部署

HDU2 已安装：

```text
/agibot/b17996_mdu
/agibot/hope_726_ws
/agibot/b17996_mdu/run_hdu_stack_a3_2.sh
```

2026-08-12 静态快照显示活动版本为：

```text
v12_return118_v10_revision
```

第二台入口显式使用 `FDU_a3_2`、`FDU_pai_2`、`Ball`、MDU `10.42.10.12` 和 Mac monitor `192.168.47.249`。Planner 算法、HP14、法向量语义和比赛规则来自 A3_1 迁移快照，没有为了第二台另改算法。

### Motive 网络（BLOCKED，必须重新探测）

预定合同：

```text
Motive server              192.168.100.111
HDU2 Motive interface IP   192.168.100.253/24
NetworkManager profile     Motive-wired-a3-2
```

2026-08-12 23:01 的最后一次只读审计没有在 HDU2 枚举到 Motive USB 以太网卡，也没有 `.253/24`。这只是当时状态：新会话不得直接宣称它仍缺失，也不得直接运行配置脚本；应先只读检查接口、地址、路由和地址冲突。

刚体球模式名称严格是 `Ball`。球可能暂时不在场，不应让启动流程因此退出；基础就绪条件是 `/FDU_a3_2/pose`。实测时还应确认 2 Hz 诊断包含 Motive 包/空包、解包对象、刚体新鲜度、Planner 和 UDP 转发状态。

## 4. FDU_a3_2 到本体外参（资产几何候选，未完成现场 hold-out）

2026-08-13 已不再直接复制第一台数值。使用 `FDU_a3.motive` 与
`FDU_a3_2.motive` 的十点几何重新配对，排除唯一约 7.5 mm 偏移 marker 后，
九点 Kabsch 拟合 RMS 为 0.872 mm。将刚体坐标差复合到第一台已解算外参后得到：

```text
translation xyz [m]
[0.059873586, -0.005693542, 0.140722160]

quaternion xyzw
[-0.010728287, 0.195794754, -0.122510581, 0.972903117]
```

HDU2 专用文件：

```text
/agibot/b17996_mdu/config/fdu_pelvis_rotation_a3_2.env
```

它是比复制值更有几何依据的候选，但 A3_2 尚无同步动捕录制，仍不是现场
hold-out 验收后的最终标定。必须用第二台十点刚体、同步关节编码器、URDF/FK、
pelvis IMU 和覆盖 READY/正反手工作区的独立姿态验证：

```text
TCP/base position p95  <= 10 mm
orientation error p95  <= 3 deg
```

失败时只改 A3_2 专用文件，不能反向修改 A3_1 外参。

## 5. MDU2 部署状态（VERIFIED 至迁移快照）

8 套生产 runtime：

```text
/agibot/b17996_mdu_726
/agibot/b17996_mdu_726_model25991_dynamic_station
/agibot/b17996_mdu_726_model26300_dynamic_station
/agibot/b17996_mdu_726_return118_model23198
/agibot/b17996_mdu_726_return118_model23296
/agibot/b17996_mdu_726_return118_model23650
/agibot/b17996_mdu_726_return118_model25038
/agibot/b17996_mdu_726_return118_model25400
```

迁移审计结果：

```text
迁移清单文件                 2,978 / 2,978 hash verified
ONNX合同                     31 total; 26 x 114D->31D; 5 x 118D->31D
ONNX CPU graph smoke          31 / 31 PASS
runtime timing self-test      8 / 8 PASS
YAML model/config references  78 checked; 0 missing
broken symlink                0
```

合成 `task_id=900000003` 已通过：

```text
HDU2 ROS -> HP14 -> MDU2 UDP -> accepted_initial -> 114D ONNX
```

该链路使用 `publish_commands=false`，没有证明实机 POLICY 行为。

### MDU2 控制工具

```text
/agibot/A3control_moveAndfaqiu.sh
/agibot/hope_pdstand_serve_player/player.sh
/agibot/faqiuS_2_xl6.sh
/agibot/激励录制播放/player.sh
```

迁移时已验证语法、依赖、单元测试、合同和 dry-run。2026-08-12 后续已经产生 A3_2 的确定性 `hope_pdstand_serve_player` 实机记录；其中一次 `1_stagger_start` 因 `tilt_deg=10.0027` 超过共同的 10° 门限而 safety abort。这个事实只说明确定性播放器实际运行过，不能扩展为 114D/118D ONNX POLICY 已通过。

## 6. 已知生产漂移（DRIFT）

迁移后 A3_1 又有更新，因此“迁移快照完整”不等于“现在与 A3_1 完全一致”。

### 118D 发布频率

2026-08-12 23:01 审计：五套 A3_1 return118 runtime 已统一为 `publish_hz: 200.0`，A3_2 迁移快照仍为 `500.0`。这属于控制合同差异，不能静默覆盖或在两机比较时忽略。

### XL6 交接

A3_1 已出现：

```text
/agibot/faqiuS_2_xl6_next
```

它支持 XL6 先在 `IDLE/no-output` 预热，再由协调器停止 MC 后进入 POLICY。A3_2 仍是较早的直接 model25400 交接实现。采用哪一版必须先审核、选择和建立回滚，不能根据文件名自动跟随。

## 7. Mac live、录制、归档和回放（VERIFIED）

配置源：

```text
/Users/hongdaliang/CODE/A3control/比赛材料/726zxl_HopeCode/deployment/b17996_monitor/robot_profiles.json
```

入口：

```text
Live
http://127.0.0.1:8765/?robot_id=a3_2

Replay
http://127.0.0.1:8765/hit-replay.html?robot_id=a3_2&session=<SESSION_ID>&robot=urdf
```

归档：

```bash
/Users/hongdaliang/CODE/A3control/比赛材料/726zxl_HopeCode/deployment/b17996_monitor/archive_recording.sh \
  --robot a3_2 --latest 40
```

A3_2 使用独立命名空间：

```text
recordings/hope_hdu_a3_2_<session>.ndjson
planner_recordings/planner_a3_2_<session>.ndjson
analysis_sessions/a3_2/<session>/
sync_sessions/a3_2/<session>/
hit_replays/hit_replay_a3_2_<session>.json
archive_jobs/a3_2__<session>.json
```

旧 URL 默认 `a3_1`。任何新增数据管道都必须保留 `robot_id`，不能让最后到达的数据覆盖另一台状态。

## 8. Real2real gap 增量结论（VERIFIED，但非电机因果辨识）

数据：

```text
A3_1  20260812_235119_262986783
A3_2  20260812_235121_225597535
```

已确认：

- 两台均为 `A3_T3D0`、Debian 12、Linux 6.1.118 PREEMPT_RT。
- 500 Hz 上层控制器、`serve_player.yaml` 和 31 关节 Kp/Kd 完全相同。
- HAL YAML 中比较的 24 项电机合同字段相同，包括 Kt 配置、MIT 范围、gear ratio、offset、direction、unit scale、slave/joint 映射和 EtherCAT 周期。
- 内核 build 时间、HAL 主程序/动态库哈希、线程数量、QoS、debug/IMU 通道和 thermal 进程不同。
- 对比记录中 A3_1 BMS 中位数约为 56.9–57.0 V、39–41°C；A3_2 约为 62.6 V、71°C。温度字段没有外部温度计校准，但必须作为重要协变量。
- 严格完全同 q_des 只找到一个 0.5 秒静态段；放宽到 2 mrad 的探索性比较有 4 段，观察到 head/ankle 等响应差异。

正确结论：**存在可观测 real2real gap，但现有数据不足以证明 gap 来自电机本体、电流环或减速器。** 缺失项包括逐电机固件/序列号、current、tau_command、post-filter q_des、饱和/温降额 flags，以及相同温度/SOC/初态下的重复同命令实验。

HAL fault 日志中的 `0x...` event ID 只能原样保留。没有厂商《洞庭A3故障事件定义》时，不得把它们猜成过温、编码器或通信错误。

## 9. 其他上下文必须遵守的操作边界

1. **先确认目标身份。** MDU2 命令必须显式经过 `192.168.47.31`；输出里同时核对 hostname、robot identity 和路径。
2. **默认只读。** “检查、分析、比较”不授权启动项目脚本、切换 MC、进入 POLICY 或发送按键。
3. **控制按键不是 shell 命令。** `p/s/r/m/y/b/q` 只应在对应交互式 runner 内按，且需要用户明确授权和现场保护。
4. **禁止并发控制器。** 启动任何 body-drive 前先只读确认没有已有 command publisher；不得为解决冲突直接 `kill -9`。
5. **保持同类迁移。** 只允许 HDU1→HDU2、MDU1→MDU2，不得把 HDU 文件部署到 MDU 或跨跳板操作。
6. **保护硬件专属数据。** 不复制或覆盖 machine-id、device secret、SSH host key、NetworkManager UUID/MAC 绑定、EtherCAT硬件配置、编码器零位和厂商固件。
7. **外参门槛优先。** A3_2 独立外参未验收前不得用“第一台看起来差不多”作为进入 POLICY 的依据。
8. **漂移先决策后同步。** 200/500 Hz 和 XL6 handoff 都是实质差异；先写差异报告，再由用户选择。
9. **保留失败原始数据。** 录制、故障、safety abort 和 tracking gap 都不能为了报告好看而删除。

## 10. 权威证据与阅读顺序

1. 第二台迁移总览：
   - `/Users/hongdaliang/CODE/A3control/SYS_README/812回答缓存【###】/A3_2_migration_20260812/README.md`
2. 第二台远端部署与 23:01 只读复核：
   - `/Users/hongdaliang/CODE/A3control/SYS_README/812回答缓存【###】/A3_2_migration_20260812/REMOTE_DEPLOYMENT_AUDIT.md`
3. 迁移机器可读状态：
   - `/Users/hongdaliang/CODE/A3control/SYS_README/812回答缓存【###】/A3_2_migration_20260812/metadata/VERIFY_RESULT.txt`
4. Real2real 总结：
   - `/Users/hongdaliang/CODE/A3control/SYS_README/813real2real_gap/README.md`
5. 底层栈差异和响应边界：
   - `/Users/hongdaliang/CODE/A3control/SYS_README/813real2real_gap/STATIC_STACK_DIFF.md`
   - `/Users/hongdaliang/CODE/A3control/SYS_README/813real2real_gap/PAIRED_RESPONSE_REPORT.md`
6. Mac 双机配置：
   - `/Users/hongdaliang/CODE/A3control/比赛材料/726zxl_HopeCode/deployment/b17996_monitor/robot_profiles.json`

## 11. 后续增量维护规则

- 新事实以 `YYYY-MM-DD HH:MM` 小节追加，不覆盖旧审计原文。
- 每项标记 `VERIFIED/TEMPORARY/BLOCKED/DRIFT/UNKNOWN`，并附 session、文件路径或只读命令证据。
- 远端发生变化时，先更新“Last verified”和差异摘要，再修改复制给其他上下文的顶部块。
- 计划、用户猜测和实测必须分开；没有数据支持时写 `UNKNOWN`。
- 涉及控制的实测必须记录：目标机器人、入口、控制器 ownership、按键、开始/结束时间、session、退出状态和是否进入 POLICY。
