#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

raw="$BACKUP_ROOT/raw_snapshot"
mkdir -p "$raw/HDU2/agibot" "$raw/MDU2/agibot" "$BACKUP_ROOT/metadata"

"$TOOL_ROOT/01_inventory_a3_2.sh"

hdu_kb="$("${HDU2_SSH_CMD[@]}" "$HDU2_SSH" "du -sk --exclude=.ota --exclude=sys --exclude=lost+found --exclude=.a3_2_staging_* --exclude=a3_2_migration_backups --exclude='*.a3_2_old_*' --exclude='*.backup_*' --exclude=data --exclude=records --exclude=records_hdu --exclude=joint_records --exclude=logs --exclude=log --exclude=bag --exclude=__pycache__ --exclude=.cache /agibot | cut -f1")"
mdu_kb="$("${MDU2_SSH_CMD[@]}" "$MDU_SSH" "du -sk --exclude=.ota --exclude=sys --exclude=lost+found --exclude=.a3_2_staging_* --exclude=a3_2_migration_backups --exclude='*.a3_2_old_*' --exclude='*.backup_*' --exclude=data --exclude=records --exclude=records_hdu --exclude=joint_records --exclude=logs --exclude=log --exclude=bag --exclude=__pycache__ --exclude=.cache /agibot | cut -f1")"
available_kb="$(df -Pk "$BACKUP_ROOT" | awk 'NR==2 {print $4}')"
required_kb=$(( (hdu_kb + mdu_kb) * 135 / 100 + 5 * 1024 * 1024 ))
printf 'hdu_estimate_kb=%s\nmdu_estimate_kb=%s\navailable_kb=%s\nrequired_kb=%s\n' \
  "$hdu_kb" "$mdu_kb" "$available_kb" "$required_kb" | tee "$BACKUP_ROOT/metadata/SPACE_PREFLIGHT.txt"
if (( available_kb < required_kb )); then
  echo "insufficient Mac space for guarded backup" >&2
  exit 12
fi

rsync -a --partial --delete-excluded "${EXCLUDES[@]}" \
  -e 'ssh -o BatchMode=yes -o ConnectTimeout=8' \
  "$HDU2_SSH:/agibot/" "$raw/HDU2/agibot/"

rsync -a --partial --delete-excluded "${EXCLUDES[@]}" \
  -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU2_SSH" \
  "$MDU_SSH:/agibot/" "$raw/MDU2/agibot/"

python3 "$TOOL_ROOT/build_manifest.py" "$raw/HDU2" \
  "$BACKUP_ROOT/metadata/HDU2_FILE_MANIFEST.tsv" "$BACKUP_ROOT/metadata/SHA256SUMS.HDU2"
python3 "$TOOL_ROOT/build_manifest.py" "$raw/MDU2" \
  "$BACKUP_ROOT/metadata/MDU2_FILE_MANIFEST.tsv" "$BACKUP_ROOT/metadata/SHA256SUMS.MDU2"

{
  printf 'role\tremote\tremote_path\tlocal_path\texclusion_policy\n'
  printf 'HDU2\t%s\t/agibot\t%s\tmetadata/EXCLUSIONS.tsv\n' "$HDU2_SSH" "$raw/HDU2/agibot"
  printf 'MDU2\t%s via %s\t/agibot\t%s\tmetadata/EXCLUSIONS.tsv\n' "$MDU_SSH" "$HDU2_SSH" "$raw/MDU2/agibot"
} >"$BACKUP_ROOT/metadata/SOURCE_PATHS.tsv"

printf 'snapshot_complete=%s\n' "$(timestamp)" | tee "$BACKUP_ROOT/metadata/BACKUP_STATUS.txt"
