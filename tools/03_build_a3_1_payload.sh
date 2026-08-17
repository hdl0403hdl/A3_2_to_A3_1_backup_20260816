#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"

raw="$BACKUP_ROOT/raw_snapshot"
payload="$BACKUP_ROOT/deployment_payload"
test -f "$BACKUP_ROOT/metadata/BACKUP_STATUS.txt"
mkdir -p "$payload/HDU1/agibot" "$payload/MDU1/agibot" "$BACKUP_ROOT/metadata"

for name in "${HDU_DEPLOY_ROOTS[@]}"; do
  source_path="$raw/HDU2/agibot/$name"
  [[ -e "$source_path" ]] || { echo "HDU2 source missing: $name" >&2; exit 20; }
  mkdir -p "$payload/HDU1/agibot/$name"
  rsync -a --delete --delete-excluded --exclude='records_hdu/' --exclude='logs/' \
    --exclude='backup*/' --exclude='__pycache__/' \
    --exclude='*.pyc' --exclude='._*' \
    "$source_path/" "$payload/HDU1/agibot/$name/"
done

# A3_1 keeps its identity, calibrated extrinsic, active Planner and registry.
rm -f \
  "$payload/HDU1/agibot/b17996_mdu/config/a3_robot_identity.env" \
  "$payload/HDU1/agibot/b17996_mdu/config/fdu_pelvis_rotation_a3_2.env" \
  "$payload/HDU1/agibot/b17996_mdu/config/active_planner_version" \
  "$payload/HDU1/agibot/b17996_mdu/config/planner_versions.tsv" \
  "$payload/HDU1/agibot/b17996_mdu/run_hdu_stack_a3_2.sh"

for name in "${MDU_DEPLOY_ROOTS[@]}"; do
  source_path="$raw/MDU2/agibot/$name"
  [[ -e "$source_path" ]] || { echo "MDU2 source missing: $name" >&2; exit 21; }
  mkdir -p "$payload/MDU1/agibot/$name"
  rsync -a --delete --delete-excluded --exclude='backup*/' "${EXCLUDES[@]}" \
    "$source_path/" "$payload/MDU1/agibot/$name/"
done
for name in "${MDU_TOP_FILES[@]}"; do
  source_path="$raw/MDU2/agibot/$name"
  [[ -e "$source_path" || -L "$source_path" ]] || { echo "MDU2 top file missing: $name" >&2; exit 22; }
  rsync -a "$source_path" "$payload/MDU1/agibot/$name"
done

# Never ship A3_2 site activation files into A3_1. Both MC variants use the
# audited A3_1 transform that travelled with MC2's site-specific package.
site_a3_1="$raw/MDU2/agibot/mc2_xl1/site_a3_1.env"
test -f "$site_a3_1"
install -m 0644 "$site_a3_1" "$payload/MDU1/agibot/mc1_xl1/site.env"
install -m 0644 "$site_a3_1" "$payload/MDU1/agibot/mc2_xl1/site.env"
rm -f "$payload/MDU1/agibot/mc2_xl1/site_a3_2.env" \
  "$payload/MDU1/agibot/mc2_xl1/deploy_a3_2.sh"

# The navigation/serve helpers only use this transform to reconstruct the raw
# marker pose for operator telemetry. Adapt that display-only inverse transform
# to A3_1; HP14 navigation itself already consumes corrected pelvis pose.
for helper in \
  "$payload/MDU1/agibot/a3control_moveAndfaqiu/A3control_moveAndfaqiu.py" \
  "$payload/MDU1/agibot/faqiuS_2_xl6/A3control_moveAndfaqiu.py" \
  "$payload/MDU1/agibot/faqiuS_2_xl6_next/A3control_moveAndfaqiu.py"; do
  test -f "$helper"
  perl -pi -e 's/FDU_a3_2/FDU_a3/g;
    s/0\.020771989, 0\.001398421, 0\.151112599/0.017662585, -0.003902495, 0.152126430/g;
    s/0\.997483328,/0.99218121843,/g;
    s/-0\.003785624,/0.00382893327,/g;
    s/0\.063379443,/0.05297072783,/g;
    s/0\.031555114,/-0.11294189240,/g' "$helper"
done

cat >"$BACKUP_ROOT/metadata/A3_1_PROTECTED_PATHS.txt" <<'EOF'
HDU:/agibot/b17996_mdu/config/a3_robot_identity.env
HDU:/agibot/b17996_mdu/config/fdu_pelvis_rotation.env
HDU:/agibot/b17996_mdu/config/fdu_pelvis_rotation_a3_2.env
HDU:/agibot/b17996_mdu/config/active_planner_version
HDU:/agibot/b17996_mdu/config/planner_versions.tsv (merge only)
HDU:NetworkManager profiles, interface names, machine-id and SSH host keys
MDU:/agibot/a3_robot_identity.json
MDU:EtherCAT, encoder zero, firmware, machine-id and SSH host keys
MDU:records, records_hdu, joint_records, logs and bags
EOF

printf '%s\n' "${HDU_DEPLOY_ROOTS[@]}" >"$BACKUP_ROOT/metadata/HDU_DEPLOY_ROOTS.txt"
printf '%s\n' "${MDU_DEPLOY_ROOTS[@]}" >"$BACKUP_ROOT/metadata/MDU_DEPLOY_ROOTS.txt"
printf '%s\n' "${MDU_TOP_FILES[@]}" >"$BACKUP_ROOT/metadata/MDU_TOP_FILES.txt"

python3 "$TOOL_ROOT/build_manifest.py" "$payload/HDU1" \
  "$BACKUP_ROOT/metadata/HDU1_PAYLOAD_MANIFEST.tsv" "$BACKUP_ROOT/metadata/SHA256SUMS.HDU1_PAYLOAD"
python3 "$TOOL_ROOT/build_manifest.py" "$payload/MDU1" \
  "$BACKUP_ROOT/metadata/MDU1_PAYLOAD_MANIFEST.tsv" "$BACKUP_ROOT/metadata/SHA256SUMS.MDU1_PAYLOAD"

# Runtime/config coupling audit. Documentation and tests are retained but not
# treated as active machine configuration.
audit="$BACKUP_ROOT/metadata/A3_2_COUPLING_SCAN.txt"
find "$payload" -type f \( -name '*.sh' -o -name '*.py' -o -name '*.yaml' \
  -o -name '*.yml' -o -name '*.env' -o -name '*.json' \) \
  -not -path '*/test*' -not -path '*/backup*' -not -path '*/runtime_source/*' \
  -not -path '*/build/*' -not -path '*/install/*' -not -name 'AUDIT_RESULTS.json' -print0 |
  xargs -0 grep -nE 'FDU_a3_2|FDU_pai_2|192\.168\.47\.31|robot_id["=: ]+a3_2|第二台A3' \
  >"$audit" || true

printf 'payload_complete=%s\n' "$(timestamp)" | tee "$BACKUP_ROOT/metadata/PAYLOAD_STATUS.txt"
