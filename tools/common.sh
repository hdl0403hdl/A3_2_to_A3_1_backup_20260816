#!/usr/bin/env bash
set -euo pipefail

TOOL_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_ROOT="$(cd -- "$TOOL_ROOT/.." && pwd)"
HDU2_SSH="${A3_2_HDU_SSH:-agi@192.168.47.31}"
HDU1_SSH="${A3_1_HDU_SSH:-agi@192.168.46.251}"
MDU_SSH="${A3_MDU_SSH:-agi@10.42.10.12}"
HDU2_SSH_CMD=(ssh -o BatchMode=yes -o ConnectTimeout=8)
HDU1_SSH_CMD=(ssh -o BatchMode=yes -o ConnectTimeout=8)
MDU2_SSH_CMD=(ssh -o BatchMode=yes -o ConnectTimeout=8 -J "$HDU2_SSH")
MDU1_SSH_CMD=(ssh -o BatchMode=yes -o ConnectTimeout=8 -J "$HDU1_SSH")

EXCLUDES=(
  --exclude='.ota/'
  --exclude='sys/'
  --exclude='lost+found/'
  --exclude='.a3_2_staging_*/'
  --exclude='a3_2_migration_backups/'
  --exclude='a3_1_update_backups/'
  --exclude='*.a3_2_old_*/'
  --exclude='*.backup_*/'
  --exclude='data/'
  --exclude='records/'
  --exclude='records_hdu/'
  --exclude='joint_records/'
  --exclude='logs/'
  --exclude='log/'
  --exclude='bag/'
  --exclude='__pycache__/'
  --exclude='.cache/'
  --exclude='.git/'
  --exclude='*.pyc'
  --exclude='._*'
  --exclude='core'
  --exclude='core.*'
  --exclude='*.sock'
)

HDU_ACTIVE_PATTERN='[r]un_hdu_stack|python3 -m [h]ope_planner.node'
MDU_ACTIVE_PATTERN='[/]agibot/.*/bin/[h]ope_pingpong_body_drive|[/]agibot/.*/bin/[h]ope_pingpong_body_drive_return118|[A]3control_moveAndfaqiu.py|[a]3_excitation_player|[a]3_pdstand_serve_player|[b]ounce_pour_agent.py|[z]ymotion.*player'

HDU_DEPLOY_ROOTS=(b17996_mdu hope_726_ws)
MDU_DEPLOY_ROOTS=(
  a3control_moveAndfaqiu a3control_moveAndfaqiu_2 a3control_moveAndfaqiu_3
  b17996_mdu_726 b17996_mdu_726_model25991_dynamic_station
  b17996_mdu_726_model26300_dynamic_station
  b17996_mdu_726_return118_model23198 b17996_mdu_726_return118_model23296
  b17996_mdu_726_return118_model23650 b17996_mdu_726_return118_model25038
  b17996_mdu_726_return118_model25400
  bounce_pour_hope_real_v3_quick faqiuS_2_xl6 faqiuS_2_xl6_next
  hitter_a3_model46000_110_v15 hitter_a3_model46000_110_v16
  hope_724 hope_pdstand_serve_player
  mc1_xl1 mc2_xl1 serve_balance_model905
  xl110_2_model17000 xl110_3 xl110_4 xl110_model50999
  xuanhong_ultimate_model46000_110
  zymotion_serve_balance_model905 zymotion3_serve_balance_model905
  zymotion4_serve_balance_model909 激励录制播放
)
MDU_TOP_FILES=(
  A3control_moveAndfaqiu.sh A3control_moveAndfaqiu_2.sh A3control_moveAndfaqiu_3.sh
  MC1_XL1.sh MC2_XL1.sh faqiuS_2_xl6.sh set_return118_command_mode.sh
)

timestamp() { date +%Y%m%d_%H%M%S; }
