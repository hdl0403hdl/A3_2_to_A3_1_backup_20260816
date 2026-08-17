#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

raw="$BACKUP_ROOT/raw_snapshot"
test -f "$BACKUP_ROOT/metadata/BACKUP_STATUS.txt"

hdu_report="$BACKUP_ROOT/metadata/HDU2_RSYNC_CHECKSUM_VERIFY.txt"
mdu_report="$BACKUP_ROOT/metadata/MDU2_RSYNC_CHECKSUM_VERIFY.txt"

rsync -anrc --delete-excluded --itemize-changes "${EXCLUDES[@]}" \
  -e 'ssh -o BatchMode=yes -o ConnectTimeout=8' \
  "$HDU2_SSH:/agibot/" "$raw/HDU2/agibot/" >"$hdu_report"

rsync -anrc --delete-excluded --itemize-changes "${EXCLUDES[@]}" \
  -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU2_SSH" \
  "$MDU_SSH:/agibot/" "$raw/MDU2/agibot/" >"$mdu_report"

if [[ -s "$hdu_report" || -s "$mdu_report" ]]; then
  {
    echo 'status=FAILED'
    echo 'reason=remote_changed_or_snapshot_mismatch'
    echo "hdu_report=$hdu_report"
    echo "mdu_report=$mdu_report"
  } | tee "$BACKUP_ROOT/metadata/SNAPSHOT_VERIFY_RESULT.txt"
  exit 40
fi

{
  echo 'status=PASS'
  echo 'method=rsync_checksum_dry_run'
  echo 'scope=/agibot project snapshot with metadata/EXCLUSIONS.tsv'
  echo "verified_at=$(timestamp)"
} | tee "$BACKUP_ROOT/metadata/SNAPSHOT_VERIFY_RESULT.txt"
