#!/usr/bin/env bash
# Batch-run BEAM over price profiles and collect surrogate training data.
#
# Usage (from full BEAM repo root, e.g. beam_smart_recovered):
#   BEAM_ROOT=/path/to/beam ./experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
#
# Or from this slim backup repo (auto-detects sibling beam_smart_recovered):
#   ./experiments/smart_charging_ev60/scripts/collect_surrogate_training_data.sh
#
# Environment variables:
#   BEAM_ROOT          Full BEAM repo with gradlew (default: ../beam_smart_recovered)
#   SLIM_REPO          Backup repo with smart-charging Scala patches (default: auto)
#   SYNC_CODE=1        Copy Scala patches from SLIM_REPO into BEAM_ROOT before runs
#   GENERATE_PROFILES=1  Regenerate price_profiles/*.csv before batch run
#   SKIP_EXISTING=1    Skip profiles that already have smart_charging_decisions.csv
#   MAX_RAM=8          Gradle -PmaxRAM value (GB)
#   CONFIG             BEAM config path relative to BEAM_ROOT

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
EXP_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

if [[ -z "${SLIM_REPO:-}" ]]; then
  if [[ -f "${EXP_DIR}/../../src/main/scala/beam/agentsim/agents/pricing/HouseholdSmartChargingManager.scala" ]]; then
    SLIM_REPO="$(cd "${EXP_DIR}/../.." && pwd)"
  else
    SLIM_REPO="${SLIM_REPO:-}"
  fi
fi

if [[ -z "${BEAM_ROOT:-}" ]]; then
  for candidate in \
    "${SLIM_REPO}/../beam_smart_recovered" \
    "${HOME}/Desktop/beam_smart_recovered" \
    "${SLIM_REPO}"; do
    if [[ -f "${candidate}/gradlew" ]]; then
      BEAM_ROOT="${candidate}"
      break
    fi
  done
fi

if [[ -z "${BEAM_ROOT:-}" || ! -f "${BEAM_ROOT}/gradlew" ]]; then
  echo "ERROR: Could not find full BEAM repo with gradlew."
  echo "Set BEAM_ROOT=/path/to/full/beam and retry."
  exit 1
fi

CONFIG="${CONFIG:-test/input/sf-light/sf-light-1k-smart-ev60.conf}"
MAX_RAM="${MAX_RAM:-8}"
GENERATE_PROFILES="${GENERATE_PROFILES:-0}"
SYNC_CODE="${SYNC_CODE:-0}"
SKIP_EXISTING="${SKIP_EXISTING:-1}"

BEAM_EXP_DIR="${BEAM_ROOT}/experiments/smart_charging_ev60"
PRICE_DIR="${BEAM_EXP_DIR}/price_profiles"
RUN_DIR="${BEAM_EXP_DIR}/runs"
PRICE_INPUT="${BEAM_ROOT}/test/input/smart-charging/price.csv"
DECISION_FILE="${BEAM_ROOT}/smart_charging_decisions.csv"

mkdir -p "${PRICE_DIR}" "${RUN_DIR}" "${BEAM_ROOT}/test/input/smart-charging"

echo "BEAM_ROOT=${BEAM_ROOT}"
echo "CONFIG=${CONFIG}"
echo "PRICE_DIR=${PRICE_DIR}"
echo "RUN_DIR=${RUN_DIR}"

if [[ "${SYNC_CODE}" == "1" && -n "${SLIM_REPO}" ]]; then
  echo "Syncing smart-charging Scala patches from ${SLIM_REPO} ..."
  rsync -a \
    "${SLIM_REPO}/src/main/scala/beam/agentsim/agents/pricing/" \
    "${BEAM_ROOT}/src/main/scala/beam/agentsim/agents/pricing/"
  rsync -a \
    "${SLIM_REPO}/src/main/scala/beam/agentsim/infrastructure/power/SitePowerManager.scala" \
    "${BEAM_ROOT}/src/main/scala/beam/agentsim/infrastructure/power/SitePowerManager.scala"
fi

if [[ "${GENERATE_PROFILES}" == "1" ]]; then
  echo "Generating price profiles ..."
  python3 "${SCRIPT_DIR}/generate_price_profiles.py"
  if [[ -n "${SLIM_REPO}" && "${SLIM_REPO}" != "${BEAM_ROOT}" ]]; then
    rsync -a "${SLIM_REPO}/experiments/smart_charging_ev60/price_profiles/" "${PRICE_DIR}/"
  fi
fi

if [[ ! -d "${PRICE_DIR}" || -z "$(ls -A "${PRICE_DIR}"/*.csv 2>/dev/null || true)" ]]; then
  echo "ERROR: No price profiles in ${PRICE_DIR}"
  echo "Run with GENERATE_PROFILES=1 or copy profiles into price_profiles/"
  exit 1
fi

SUMMARY_CSV="${BEAM_EXP_DIR}/batch_run_summary.csv"
echo "profile,status,return_code,elapsed_sec,output_dir" > "${SUMMARY_CSV}"

run_profile() {
  local profile_path="$1"
  local profile_name
  profile_name="$(basename "${profile_path}" .csv)"

  if [[ "${profile_name}" == "price_profile_summary" ]]; then
    return 0
  fi

  local out_dir="${RUN_DIR}/${profile_name}"
  mkdir -p "${out_dir}"

  if [[ "${SKIP_EXISTING}" == "1" && -f "${out_dir}/smart_charging_decisions.csv" ]]; then
    echo "[SKIP] ${profile_name}: output exists"
    echo "${profile_name},skipped,0,0,${out_dir}" >> "${SUMMARY_CSV}"
    python3 "${SCRIPT_DIR}/build_aggregate_load.py" "${out_dir}/smart_charging_decisions.csv" || true
    return 0
  fi

  echo "================================================================================"
  echo "[RUN] ${profile_name}"
  echo "================================================================================"

  # Avoid JMX port conflicts from leftover BEAM/Java processes
  pkill -f 'beam.sim.RunBeam' 2>/dev/null || true
  pkill -f 'GradleDaemon' 2>/dev/null || true
  sleep 2

  rm -f "${DECISION_FILE}"
  cp "${profile_path}" "${PRICE_INPUT}"
  cp "${profile_path}" "${out_dir}/price.csv"

  local log_path="${out_dir}/run.log"
  local start_ts end_ts elapsed rc

  start_ts="$(date +%s)"
  set +e
  (
    cd "${BEAM_ROOT}"
    ./gradlew --no-daemon :run \
      --rerun-tasks \
      -PmaxRAM="${MAX_RAM}" \
      -PappArgs="['--config', '${CONFIG}']"
  ) > "${log_path}" 2>&1
  rc=$?
  set -e
  end_ts="$(date +%s)"
  elapsed=$((end_ts - start_ts))

  if [[ ${rc} -ne 0 ]]; then
    echo "[FAILED] ${profile_name}: gradle exit ${rc} (see ${log_path})"
    echo "${profile_name},failed,${rc},${elapsed},${out_dir}" >> "${SUMMARY_CSV}"
    return 0
  fi

  if [[ ! -f "${DECISION_FILE}" ]]; then
    echo "[FAILED] ${profile_name}: smart_charging_decisions.csv not found"
    echo "${profile_name},missing_output,${rc},${elapsed},${out_dir}" >> "${SUMMARY_CSV}"
    return 0
  fi

  cp "${DECISION_FILE}" "${out_dir}/smart_charging_decisions.csv"
  python3 "${SCRIPT_DIR}/build_aggregate_load.py" "${out_dir}/smart_charging_decisions.csv"

  cat > "${out_dir}/metadata.json" <<EOF
{
  "profile": "${profile_name}",
  "status": "success",
  "return_code": ${rc},
  "elapsed_sec": ${elapsed},
  "config": "${CONFIG}",
  "price_file": "${out_dir}/price.csv",
  "decisions_file": "${out_dir}/smart_charging_decisions.csv",
  "aggregate_load_file": "${out_dir}/aggregate_household_load.csv"
}
EOF

  echo "[DONE] ${profile_name}: ${elapsed}s"
  echo "${profile_name},success,${rc},${elapsed},${out_dir}" >> "${SUMMARY_CSV}"
}

profile_count=0
for profile_path in "${PRICE_DIR}"/*.csv; do
  [[ -f "${profile_path}" ]] || continue
  profile_count=$((profile_count + 1))
  run_profile "${profile_path}"
done
echo "Processed ${profile_count} csv files in ${PRICE_DIR}"

echo "Building surrogate training table ..."
(
  cd "${BEAM_ROOT}"
  python3 "${SCRIPT_DIR}/build_surrogate_training_table.py" \
    --runs-dir "${RUN_DIR}" \
    --output "${BEAM_EXP_DIR}/surrogate/datasets/surrogate_training_table_v0.csv"
)

echo ""
echo "Batch collection finished."
echo "  Run summary:     ${SUMMARY_CSV}"
echo "  Training table:  ${BEAM_EXP_DIR}/surrogate/datasets/surrogate_training_table_v0.csv"
echo ""
echo "Successful runs:"
find "${RUN_DIR}" -name smart_charging_decisions.csv | sort
