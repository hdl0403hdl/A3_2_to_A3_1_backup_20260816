#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

stamp="${1:-}"
[[ -n "$stamp" ]] || { echo "usage: $0 INSTALL_STAMP" >&2; exit 2; }
[[ "${A3_1_ROLLBACK_CONFIRM:-}" == ROLLBACK_A3_1_UPDATE ]] || {
  echo 'refused: set A3_1_ROLLBACK_CONFIRM=ROLLBACK_A3_1_UPDATE' >&2
  exit 10
}
before="$BACKUP_ROOT/target_before/$stamp"
test -d "$before/HDU1/agibot"
test -d "$before/MDU1/agibot"

hdu_processes="$("${HDU1_SSH_CMD[@]}" "$HDU1_SSH" "pgrep -af '$HDU_ACTIVE_PATTERN'" || true)"
mdu_processes="$("${MDU1_SSH_CMD[@]}" "$MDU_SSH" "pgrep -af '$MDU_ACTIVE_PATTERN'" || true)"
[[ -z "$hdu_processes" && -z "$mdu_processes" ]] || { echo 'refused: project controller active'; exit 30; }

# Preserve anything that did not exist before installation by moving it aside.
# This makes rollback exact without deleting potentially useful files.
failed_stamp="$(timestamp)"
failed_root="/agibot/a3_1_failed_update_${failed_stamp}"
"${HDU1_SSH_CMD[@]}" "$HDU1_SSH" "mkdir -p '$failed_root/HDU'"
"${MDU1_SSH_CMD[@]}" "$MDU_SSH" "mkdir -p '$failed_root/MDU'"

while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  if ! grep -Fxq "$name" "$before/metadata/HDU_EXISTING.txt" 2>/dev/null; then
    "${HDU1_SSH_CMD[@]}" "$HDU1_SSH" "test ! -e /agibot/'$name' || mv /agibot/'$name' '$failed_root/HDU/'"
  fi
done <"$before/metadata/HDU_ROOTS.txt"
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  if ! grep -Fxq "$name" "$before/metadata/MDU_EXISTING.txt" 2>/dev/null; then
    "${MDU1_SSH_CMD[@]}" "$MDU_SSH" "test ! -e /agibot/'$name' || mv /agibot/'$name' '$failed_root/MDU/'"
  fi
done <"$before/metadata/MDU_ROOTS.txt"
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  if ! grep -Fxq "$name" "$before/metadata/MDU_TOP_EXISTING.txt" 2>/dev/null; then
    "${MDU1_SSH_CMD[@]}" "$MDU_SSH" "test ! -e /agibot/'$name' -a ! -L /agibot/'$name' || mv /agibot/'$name' '$failed_root/MDU/'"
  fi
done <"$before/metadata/MDU_TOP_FILES.txt"

while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  rsync -rlptc --delete "${EXCLUDES[@]}" -e 'ssh -o BatchMode=yes -o ConnectTimeout=8' \
    "$before/HDU1/agibot/$name/" "$HDU1_SSH:/agibot/$name/"
done <"$before/metadata/HDU_EXISTING.txt"
while IFS= read -r name; do
  [[ -n "$name" ]] || continue
  rsync -rlptc --delete "${EXCLUDES[@]}" \
    -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU1_SSH" \
    "$before/MDU1/agibot/$name/" "$MDU_SSH:/agibot/$name/"
done <"$before/metadata/MDU_EXISTING.txt"
if [[ -f "$before/metadata/MDU_TOP_EXISTING.txt" ]]; then
  while IFS= read -r name; do
    [[ -n "$name" ]] || continue
    rsync -a -e "ssh -o BatchMode=yes -o ConnectTimeout=8 -o ProxyJump=$HDU1_SSH" \
      "$before/MDU1/agibot/$name" "$MDU_SSH:/agibot/$name"
  done <"$before/metadata/MDU_TOP_EXISTING.txt"
fi

printf 'status=ROLLED_BACK\nstamp=%s\ncontrol_started=false\n' "$stamp" \
  | tee "$BACKUP_ROOT/metadata/A3_1_DEPLOYMENT_STATUS.txt"
