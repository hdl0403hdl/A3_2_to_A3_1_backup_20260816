#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

test -f "$BACKUP_ROOT/metadata/PAYLOAD_STATUS.txt"
stamp="$(timestamp)"
report="$BACKUP_ROOT/metadata/A3_1_PREFLIGHT_${stamp}.txt"

if ! "${HDU1_SSH_CMD[@]}" "$HDU1_SSH" true 2>"$BACKUP_ROOT/metadata/A3_1_HDU_CONNECT_ERROR.txt"; then
  printf 'status=WAITING_FOR_A3_1\nchecked_at=%s\nreason=HDU1_SSH_UNREACHABLE\n' "$stamp" \
    | tee "$BACKUP_ROOT/metadata/A3_1_DEPLOYMENT_STATUS.txt"
  exit 20
fi
if ! "${MDU1_SSH_CMD[@]}" "$MDU_SSH" true 2>"$BACKUP_ROOT/metadata/A3_1_MDU_CONNECT_ERROR.txt"; then
  printf 'status=WAITING_FOR_A3_1\nchecked_at=%s\nreason=MDU1_SSH_UNREACHABLE\n' "$stamp" \
    | tee "$BACKUP_ROOT/metadata/A3_1_DEPLOYMENT_STATUS.txt"
  exit 21
fi

{
  echo 'schema=hope726.a3_1_preflight.v1'
  echo "checked_at=$stamp"
  echo '--- HDU1 ---'
  "${HDU1_SSH_CMD[@]}" "$HDU1_SSH" 'set -eu
    hostname; date -Is; uname -a; df -h /agibot
    cat /agibot/b17996_mdu/config/a3_robot_identity.env 2>/dev/null || true
    cat /agibot/b17996_mdu/config/fdu_pelvis_rotation.env
    echo active=$(cat /agibot/b17996_mdu/config/active_planner_version 2>/dev/null || echo UNSET)
    cat /agibot/b17996_mdu/config/planner_versions.tsv 2>/dev/null || true
    pgrep -af "run_hdu_stack|hope_planner|motion_capture_tracking|optitrack" || true
  '
  echo '--- MDU1 ---'
  "${MDU1_SSH_CMD[@]}" "$MDU_SSH" 'set -eu
    hostname; date -Is; uname -a; df -h /agibot
    cat /agibot/a3_robot_identity.json 2>/dev/null || true
    for p in /agibot/MC1_XL1.sh /agibot/MC2_XL1.sh /agibot/mc1_xl1 /agibot/mc2_xl1; do
      test ! -e "$p" || stat -c "%F %a %U:%G %s %y %n" "$p"
    done
    pgrep -af "hope_pingpong|A3control|a3_excitation|a3_pdstand|bounce_pour|zymotion" || true
  '
} >"$report"

# Menu number and version id must either both be absent or already match.
"${HDU1_SSH_CMD[@]}" "$HDU1_SSH" 'python3 - <<'"'"'PY'"'"'
from pathlib import Path
p=Path("/agibot/b17996_mdu/config/planner_versions.tsv")
rows=[]
if p.exists():
    for line in p.read_text().splitlines():
        parts=line.split()
        if len(parts) >= 2 and parts[0].isdigit(): rows.append((int(parts[0]),parts[1]))
for number,name in rows:
    if number == 18 and name != "v18_lateral_margin_return118":
        raise SystemExit(f"menu 18 conflict: {name}")
    if name == "v18_lateral_margin_return118" and number != 18:
        raise SystemExit(f"V18 id conflict: menu {number}")
print("v18_registry_preflight=PASS")
PY'

printf 'status=READY_FOR_AUDIT_ONLY\nchecked_at=%s\nreport=%s\n' "$stamp" "$report" \
  | tee "$BACKUP_ROOT/metadata/A3_1_DEPLOYMENT_STATUS.txt"

