#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

mkdir -p "$BACKUP_ROOT/metadata/SYSTEM_FINGERPRINTS"
stamp="$(timestamp)"

"${HDU2_SSH_CMD[@]}" "$HDU2_SSH" 'set -eu
echo "schema=hope726.a3_2_hdu_inventory.v1"
hostname; date -Is; uname -a; df -h /agibot
ip -br address || true
find /agibot -mindepth 1 -maxdepth 1 -printf "%y\t%m\t%u:%g\t%s\t%TY-%Tm-%TdT%TH:%TM:%TS\t%p\t%l\n" | sort
echo "--- planner registry ---"
cat /agibot/b17996_mdu/config/planner_versions.tsv 2>/dev/null || true
echo "--- active planner ---"
cat /agibot/b17996_mdu/config/active_planner_version 2>/dev/null || true
echo "--- project processes ---"
pgrep -af "run_hdu_stack|hope_planner|motion_capture_tracking|optitrack" || true
' >"$BACKUP_ROOT/metadata/SYSTEM_FINGERPRINTS/HDU2_${stamp}.txt"

"${MDU2_SSH_CMD[@]}" "$MDU_SSH" 'set -eu
echo "schema=hope726.a3_2_mdu_inventory.v1"
hostname; date -Is; uname -a; df -h /agibot
find /agibot -mindepth 1 -maxdepth 1 -printf "%y\t%m\t%u:%g\t%s\t%TY-%Tm-%TdT%TH:%TM:%TS\t%p\t%l\n" | sort
echo "--- robot identity ---"
cat /agibot/a3_robot_identity.json 2>/dev/null || true
echo "--- MC entrypoints ---"
for p in /agibot/MC1_XL1.sh /agibot/MC2_XL1.sh; do stat -c "%F %a %U:%G %s %y %n" "$p" 2>/dev/null || true; readlink "$p" 2>/dev/null || true; done
echo "--- project processes ---"
pgrep -af "hope_pingpong|A3control|a3_excitation|a3_pdstand|bounce_pour|zymotion" || true
' >"$BACKUP_ROOT/metadata/SYSTEM_FINGERPRINTS/MDU2_${stamp}.txt"

cat >"$BACKUP_ROOT/metadata/EXCLUSIONS.tsv" <<'EOF'
pattern\treason\tcontent_copied
/agibot/data/\tVendor logs, 50GB bags and runtime data; fingerprint only\tno
/agibot/.ota/\tVendor OTA mirror contains protected NetworkManager secrets and is not project runtime\tno
/agibot/sys/\tLive vendor IPC sockets and generated runtime state\tno
/agibot/lost+found/\tFilesystem administration directory\tno
/agibot/.a3_2_staging_*/\tCompleted migration staging copy; canonical deployment is backed up\tno
/agibot/a3_2_migration_backups/\tHistorical migration backups; canonical deployment is backed up\tno
*.a3_2_old_*/ or *.backup_*/\tHistorical duplicate trees; canonical deployment is backed up\tno
records/\tRobot recordings explicitly excluded by user\tno
records_hdu/\tHDU recordings explicitly excluded by user\tno
joint_records/\tJoint recordings explicitly excluded by user\tno
logs/ or log/\tRuntime logs are not deployment state\tno
bag/\tROS/system bags are recordings\tno
__pycache__/, .cache/, *.pyc\tRegenerable cache\tno
.git/\tRepository metadata is not robot runtime\tno
core, core.*\tCrash dumps\tno
*.sock\tLive Unix sockets cannot be archived as project files\tno
EOF

printf 'inventory_complete=%s\n' "$stamp"
