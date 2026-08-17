#!/usr/bin/env bash
set -euo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)/common.sh"
stamp="${1:-$(timestamp)}"
report="$BACKUP_ROOT/metadata/A3_1_VERIFY_${stamp}.txt"

{
  echo 'schema=hope726.a3_1_post_install_verify.v1'
  echo "stamp=$stamp"
  "${HDU1_SSH_CMD[@]}" "$HDU1_SSH" 'set -eu
    /agibot/b17996_mdu/planner_version.sh check v18_lateral_margin_return118
    cfg=/agibot/b17996_mdu/planner_versions/v18_lateral_margin_return118/config/hope_planner.yaml
    grep -q "x_hit: 0.20" "$cfg"
    grep -q "strike_lateral_margin_m: 0.150" "$cfg"
    grep -q "strike_lateral_hysteresis_m: 0.020" "$cfg"
    ! grep -Eq "FDU_a3_2|FDU_pai_2|robot_id.*a3_2" /agibot/b17996_mdu/config/a3_robot_identity.env 2>/dev/null
    python3 -m py_compile \
      /agibot/b17996_mdu/planner_versions/v18_lateral_margin_return118/python/hope_planner/constants.py \
      /agibot/b17996_mdu/planner_versions/v18_lateral_margin_return118/python/hope_planner/planner.py \
      /agibot/b17996_mdu/planner_versions/v18_lateral_margin_return118/python/hope_planner/node.py
    echo "active_planner=$(cat /agibot/b17996_mdu/config/active_planner_version 2>/dev/null || echo UNSET)"
    test -z "$(pgrep -af "[r]un_hdu_stack|python3 -m [h]ope_planner.node" || true)"
    echo HDU1_VERIFY=PASS
  '
  "${MDU1_SSH_CMD[@]}" "$MDU_SSH" 'set -eu
    test "$(readlink /agibot/MC1_XL1.sh)" = /agibot/mc1_xl1/MC1_XL1.sh
    test "$(readlink /agibot/MC2_XL1.sh)" = /agibot/mc2_xl1/MC2_XL1.sh
    bash -n /agibot/MC1_XL1.sh /agibot/MC2_XL1.sh \
      /agibot/mc1_xl1/run_live_record_xl1_handoff.sh \
      /agibot/mc2_xl1/run_live_record_xl1_handoff.sh
    python3 -m py_compile /agibot/mc1_xl1/A3control_moveAndfaqiu.py \
      /agibot/mc2_xl1/A3control_moveAndfaqiu.py
    python3 /agibot/mc1_xl1/test_mc1_xl1_handoff.py
    python3 /agibot/mc2_xl1/test_mc2_xl1_handoff.py
    grep -q "0.017662585,-0.003902495,0.152126430" /agibot/mc1_xl1/site.env
    grep -q "0.017662585,-0.003902495,0.152126430" /agibot/mc2_xl1/site.env
    test -f /agibot/bounce_pour_hope_real_v3_quick/bounce_pour_agent.py
    test -x /agibot/b17996_mdu_726_return118_model23198/run_live_record_xl118_1.sh
    python3 - <<'"'"'PY'"'"'
import json
from pathlib import Path
p=Path("/agibot/a3_robot_identity.json")
if p.exists():
    value=json.loads(p.read_text())
    assert value.get("robot_id", "a3_1") == "a3_1", value
PY
    test -z "$(pgrep -af "[h]ope_pingpong_body_drive|[A]3control_moveAndfaqiu.py|[a]3_excitation_player|[a]3_pdstand_serve_player|[b]ounce_pour_agent.py" || true)"
    echo MDU1_VERIFY=PASS
  '
} | tee "$report"

printf 'status=INSTALLED_STATIC_VERIFY_PASS\nstamp=%s\nreport=%s\ncontrol_started=false\n' "$stamp" "$report" \
  | tee "$BACKUP_ROOT/metadata/A3_1_DEPLOYMENT_STATUS.txt"
