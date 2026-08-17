#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

[[ "${A3_1_INSTALL_CONFIRM:-}" == INSTALL_A3_2_PORTABLE_UPDATES_TO_A3_1 ]] || {
  echo 'refused: set A3_1_INSTALL_CONFIRM=INSTALL_A3_2_PORTABLE_UPDATES_TO_A3_1' >&2
  exit 10
}
test -f "$BACKUP_ROOT/metadata/PAYLOAD_STATUS.txt"
"$TOOL_ROOT/04_audit_a3_1.sh"

stamp="$(timestamp)"
before="$BACKUP_ROOT/target_before/$stamp"
mkdir -p "$before/HDU1/agibot" "$before/MDU1/agibot" "$before/metadata"
remote_backup="/agibot/a3_1_update_backups/$stamp"
log="$BACKUP_ROOT/metadata/A3_1_INSTALL_${stamp}.log"
exec > >(tee "$log") 2>&1

hdu_processes="$("${HDU1_SSH_CMD[@]}" "$HDU1_SSH" "pgrep -af '$HDU_ACTIVE_PATTERN'" || true)"
mdu_processes="$("${MDU1_SSH_CMD[@]}" "$MDU_SSH" "pgrep -af '$MDU_ACTIVE_PATTERN'" || true)"
[[ -z "$hdu_processes" ]] || { echo "refused: HDU1 project process active"; printf '%s\n' "$hdu_processes"; exit 30; }
[[ -z "$mdu_processes" ]] || { echo "refused: MDU1 controller active"; printf '%s\n' "$mdu_processes"; exit 31; }

printf '%s\n' "${HDU_DEPLOY_ROOTS[@]}" >"$before/metadata/HDU_ROOTS.txt"
printf '%s\n' "${MDU_DEPLOY_ROOTS[@]}" >"$before/metadata/MDU_ROOTS.txt"
printf '%s\n' "${MDU_TOP_FILES[@]}" >"$before/metadata/MDU_TOP_FILES.txt"
: >"$before/metadata/HDU_EXISTING.txt"
: >"$before/metadata/MDU_EXISTING.txt"
: >"$before/metadata/MDU_TOP_EXISTING.txt"

for name in "${HDU_DEPLOY_ROOTS[@]}"; do
  if "${HDU1_SSH_CMD[@]}" "$HDU1_SSH" "test -d /agibot/'$name'"; then
    echo "$name" >>"$before/metadata/HDU_EXISTING.txt"
    mkdir -p "$before/HDU1/agibot/$name"
    rsync -a "${EXCLUDES[@]}" -e 'ssh -o BatchMode=yes -o ConnectTimeout=8' \
      "$HDU1_SSH:/agibot/$name/" "$before/HDU1/agibot/$name/"
  fi
done
for name in "${MDU_DEPLOY_ROOTS[@]}"; do
  if "${MDU1_SSH_CMD[@]}" "$MDU_SSH" "test -d /agibot/'$name'"; then
    echo "$name" >>"$before/metadata/MDU_EXISTING.txt"
    mkdir -p "$before/MDU1/agibot/$name"
    rsync -a "${EXCLUDES[@]}" -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU1_SSH" \
      "$MDU_SSH:/agibot/$name/" "$before/MDU1/agibot/$name/"
  fi
done
for name in "${MDU_TOP_FILES[@]}"; do
  if "${MDU1_SSH_CMD[@]}" "$MDU_SSH" "test -e /agibot/'$name' -o -L /agibot/'$name'"; then
    echo "$name" >>"$before/metadata/MDU_TOP_EXISTING.txt"
    rsync -a -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU1_SSH" \
      "$MDU_SSH:/agibot/$name" "$before/MDU1/agibot/$name"
  fi
done
python3 "$TOOL_ROOT/build_manifest.py" "$before" \
  "$before/metadata/TARGET_BEFORE_MANIFEST.tsv" "$before/metadata/SHA256SUMS.target_before"

active_before="$("${HDU1_SSH_CMD[@]}" "$HDU1_SSH" 'cat /agibot/b17996_mdu/config/active_planner_version 2>/dev/null || true')"
printf '%s\n' "$active_before" >"$before/metadata/ACTIVE_PLANNER_BEFORE.txt"
"${HDU1_SSH_CMD[@]}" "$HDU1_SSH" "mkdir -p '$remote_backup/HDU'"
"${MDU1_SSH_CMD[@]}" "$MDU_SSH" "mkdir -p '$remote_backup/MDU'"

for name in "${HDU_DEPLOY_ROOTS[@]}"; do
  args=(-rlptc --itemize-changes --backup --backup-dir="$remote_backup/HDU/$name" "${EXCLUDES[@]}")
  if [[ "$name" == b17996_mdu ]]; then
    args+=(--exclude='/config/a3_robot_identity.env' --exclude='/config/fdu_pelvis_rotation.env'
      --exclude='/config/fdu_pelvis_rotation_a3_2.env' --exclude='/config/active_planner_version'
      --exclude='/config/planner_versions.tsv' --exclude='/run_hdu_stack_a3_2.sh')
  fi
  rsync "${args[@]}" -e 'ssh -o BatchMode=yes -o ConnectTimeout=8' \
    "$BACKUP_ROOT/deployment_payload/HDU1/agibot/$name/" "$HDU1_SSH:/agibot/$name/"
done

"${HDU1_SSH_CMD[@]}" "$HDU1_SSH" 'set -eu
registry=/agibot/b17996_mdu/config/planner_versions.tsv
if ! awk '\''$1 == 18 && $2 == "v18_lateral_margin_return118" {ok=1} END {exit !ok}'\'' "$registry"; then
  printf "%s\n" "18 v18_lateral_margin_return118" >>"$registry"
fi
'

for name in "${MDU_DEPLOY_ROOTS[@]}"; do
  rsync -rlptc --itemize-changes --backup --backup-dir="$remote_backup/MDU/$name" \
    "${EXCLUDES[@]}" -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU1_SSH" \
    "$BACKUP_ROOT/deployment_payload/MDU1/agibot/$name/" "$MDU_SSH:/agibot/$name/"
done
for name in "${MDU_TOP_FILES[@]}"; do
  rsync -rlptc --itemize-changes --backup --backup-dir="$remote_backup/MDU/top" \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU1_SSH" \
    "$BACKUP_ROOT/deployment_payload/MDU1/agibot/$name" "$MDU_SSH:/agibot/$name"
done

active_after="$("${HDU1_SSH_CMD[@]}" "$HDU1_SSH" 'cat /agibot/b17996_mdu/config/active_planner_version 2>/dev/null || true')"
[[ "$active_after" == "$active_before" ]] || { echo 'active Planner changed unexpectedly' >&2; exit 40; }

printf 'install_stamp=%s\ntarget_before=%s\nremote_backup=%s\n' "$stamp" "$before" "$remote_backup" \
  >"$BACKUP_ROOT/metadata/LAST_INSTALL.txt"
"$TOOL_ROOT/06_verify_a3_1.sh" "$stamp"
