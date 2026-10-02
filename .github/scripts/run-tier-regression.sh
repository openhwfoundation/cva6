#!/usr/bin/env bash
# Copyright 2026 OpenHW Group
# Licensed under the Apache License, Version 2.0, see LICENSE for details.
# SPDX-License-Identifier: Apache-2.0

set -o pipefail

RESULTS_DIR="${RESULTS_DIR:-ci-results}"
RUN_LOG="$(pwd)/${RESULTS_DIR}/run.log"
FAILURE_SUMMARY="$(pwd)/${RESULTS_DIR}/failure_summary.log"
EXIT_CODE_FILE="$(pwd)/${RESULTS_DIR}/exit_code"
COOK_CONFIG_DIR="${COOK_CONFIG_DIR:-${RUNNER_TEMP:-/tmp}/cva6-cook-config}"

mkdir -p "${RESULTS_DIR}"
: > "${RUN_LOG}"
: > "${FAILURE_SUMMARY}"
echo "1" > "${EXIT_CODE_FILE}"

TIER_NAME="${TIER_NAME:-Tier}"
TIER_MODE="${TIER_MODE:-script}"
TIER_CONFIG="${TIER_CONFIG:?TIER_CONFIG is required}"
TIER_TESTCASE="${TIER_TESTCASE:-}"
TIER_SIMULATOR="${TIER_SIMULATOR:-veri-testharness,spike}"
TIER_INSTALL_SCRIPT="${TIER_INSTALL_SCRIPT:-}"
TIER_TESTLIST="${TIER_TESTLIST:-}"
TIER_TEST_NAME="${TIER_TEST_NAME:-}"
TIER_LINKER="${TIER_LINKER:-}"
TIER_HWCONFIG_OPTS="${TIER_HWCONFIG_OPTS:-}"
TIER_TOOLCHAIN="${TIER_TOOLCHAIN:-github_actions_gcc}"
TIER_COMPILER_MARCH="${TIER_COMPILER_MARCH:-}"
TIER_ISS_TIMEOUT="${TIER_ISS_TIMEOUT:-500}"

case "${TIER_MODE}" in
  script)
    : "${TIER_TESTCASE:?TIER_TESTCASE is required for script mode}"
    ;;
  testlist)
    : "${TIER_TESTCASE:?TIER_TESTCASE is required for testlist mode}"
    : "${TIER_TESTLIST:?TIER_TESTLIST is required for testlist mode}"
    ;;
  cook-testlist)
    : "${TIER_TESTLIST:?TIER_TESTLIST is required for cook-testlist mode}"
    : "${TIER_COMPILER_MARCH:?TIER_COMPILER_MARCH is required for cook-testlist mode}"
    ;;
  *)
    echo "ERROR: unsupported TIER_MODE=${TIER_MODE}" >&2
    exit 2
    ;;
esac

log_info() {
  echo "$*" | tee -a "${RUN_LOG}"
}

run_logged() {
  set +e
  "$@" > >(tee -a "${RUN_LOG}") 2>&1
  local cmd_rc=$?
  return "${cmd_rc}"
}

source_logged() {
  local script_path="$1"
  set +e
  # shellcheck source=/dev/null
  source "${script_path}" > >(tee -a "${RUN_LOG}") 2>&1
  local source_rc=$?
  return "${source_rc}"
}

record_rc() {
  local step_rc="$1"
  if [ "${step_rc}" -ne 0 ] && [ "${rc}" -eq 0 ]; then
    rc="${step_rc}"
  fi
}

append_failure() {
  echo "$*" | tee -a "${FAILURE_SUMMARY}" >&2
}

collect_reports() {
  mkdir -p "${RESULTS_DIR}/reports"
  find verif/sim -name "iss_regr.log" \
    -exec cp {} "${RESULTS_DIR}/" \; 2>/dev/null || true
  if [ -f "${COOK_CONFIG_DIR}/environment.yml" ]; then
    cp "${COOK_CONFIG_DIR}/environment.yml" \
      "${RESULTS_DIR}/toolchain-environment.yml"
  fi
  if [ -d artifacts/reports ]; then
    find artifacts/reports -maxdepth 1 -type f -name 'report_*.yml' \
      -exec cp {} "${RESULTS_DIR}/reports/" \;
  fi
}

write_metadata() {
  {
    echo "schema_version=1"
    echo "tier=${TIER_NAME}"
    echo "mode=${TIER_MODE}"
    echo "target=${TIER_CONFIG}"
    echo "testcase=${TIER_TESTCASE}"
    echo "testlist=${TIER_TESTLIST}"
    echo "simulator=${TIER_SIMULATOR}"
    echo "toolchain=${TIER_TOOLCHAIN}"
    echo "compiler_march=${TIER_COMPILER_MARCH}"
    echo "spike_tandem=${SPIKE_TANDEM:-unset}"
    echo "source_revision=$(git rev-parse HEAD)"
    echo "event_head_sha=${TIER_EVENT_HEAD_SHA:-unknown}"
    echo "event_base_sha=${TIER_EVENT_BASE_SHA:-unknown}"
  } > "${RESULTS_DIR}/metadata.txt"
}

scan_for_failures() {
  local matches
  local -a scan_files=("${RUN_LOG}")

  while IFS= read -r -d '' file_path; do
    scan_files+=("${file_path}")
  done < <(
    find verif/sim -type f \
      \( -name "*.log" -o -name "*.txt" -o -name "iss_regr.log" \) \
      -print0 2>/dev/null || true
    if [ -d "build/${TIER_CONFIG}" ]; then
      find "build/${TIER_CONFIG}" -type f \
        \( -name "*.log" -o -name "*.txt" \) \
        -print0 2>/dev/null || true
    fi
  )

  matches="$(
    grep -HnE \
      "\\[FAILED\\]|SIMULATION FAILED|(^|[^0-9])[1-9][0-9]* FAILED|:[[:space:]]+FAIL[[:space:]]+\\([1-9][0-9]*\\)|\\*\\*\\*[[:space:]]+FAILED[[:space:]]+\\*\\*\\*|ERROR[[:space:]]+return code:|bad syscall|unrecognized opcode|extension .* required|make(\\[[0-9]+\\])?: \\*\\*\\*.*Error|terminate called|Traceback \\(most recent call last\\)" \
      "${scan_files[@]}" 2>/dev/null || true
  )"

  if [ -n "${matches}" ]; then
    append_failure "ERROR: failure patterns were found in regression logs."
    echo "${matches}" | tee -a "${FAILURE_SUMMARY}" >&2
    return 1
  fi

  return 0
}

scan_iss_traces() {
  local matches=""
  local critical_patterns
  critical_patterns="ERROR[[:space:]]+return code:|bad syscall|unrecognized opcode|extension .* required|terminate called|Traceback \\(most recent call last\\)"

  while IFS= read -r -d '' file_path; do
    local critical_matches
    local last_status

    critical_matches="$(grep -HnE "${critical_patterns}" "${file_path}" 2>/dev/null || true)"
    if [ -n "${critical_matches}" ]; then
      matches+="${critical_matches}"$'\n'
    fi

    last_status="$(
      grep -nE "\\*\\*\\*[[:space:]]+(FAILED|SUCCESS)[[:space:]]+\\*\\*\\*|SIMULATION FAILED" \
        "${file_path}" 2>/dev/null | tail -n 1 || true
    )"
    if [[ -n "${last_status}" && "${last_status}" != *"SUCCESS"* ]]; then
      matches+="${file_path}:${last_status}"$'\n'
    fi
  done < <(
    find verif/sim -type f -name "*.iss" -print0 2>/dev/null || true
    if [ -d "build/${TIER_CONFIG}" ]; then
      find "build/${TIER_CONFIG}" -type f -name "*.iss" \
        -print0 2>/dev/null || true
    fi
  )

  if [ -n "${matches}" ]; then
    append_failure "ERROR: ISS trace failure patterns were found."
    printf "%s" "${matches}" | tee -a "${FAILURE_SUMMARY}" >&2
    return 1
  fi

  return 0
}

rc=0

log_info "Running ${TIER_NAME}: ${TIER_CONFIG} / ${TIER_TESTCASE} (${TIER_MODE})"
write_metadata

source_logged verif/sim/setup-env.sh
record_rc "$?"

if [ "${rc}" -eq 0 ] && [ "${TIER_MODE}" = "cook-testlist" ]; then
  if [ -n "${TIER_INSTALL_SCRIPT}" ]; then
    source_logged "verif/regress/${TIER_INSTALL_SCRIPT}.sh"
    record_rc "$?"
  fi

  if [ "${rc}" -eq 0 ]; then
    run_logged python3 .github/scripts/prepare-cook-toolchains.py \
      --output-dir "${COOK_CONFIG_DIR}"
    record_rc "$?"
  fi

  export CONFIG_DIR="${COOK_CONFIG_DIR}"

  export DASHBOARD_JOB_TITLE="${TIER_CONFIG} ${TIER_TESTCASE} public tandem"
  export DASHBOARD_JOB_DESCRIPTION="cook.py Verilator TestHarness and Spike validation"
  export DASHBOARD_JOB_CATEGORY="testlist"
  export CI_JOB_ID="${GITHUB_RUN_ID:-local}-${GITHUB_RUN_ATTEMPT:-1}-${TIER_CONFIG}-${TIER_TESTCASE}"
  export CI_JOB_URL="https://github.com/${GITHUB_REPOSITORY:-local}/actions/runs/${GITHUB_RUN_ID:-local}"
  export CI_JOB_STAGE="${TIER_NAME}"

  if [ "${rc}" -eq 0 ]; then
    run_logged ./cook.py sw-compile-testlist \
      --target "${TIER_CONFIG}" \
      --toolchain "${TIER_TOOLCHAIN}" \
      --testlist "${TIER_TESTLIST}" \
      --march "${TIER_COMPILER_MARCH}"
    record_rc "$?"
  fi

  if [ "${rc}" -eq 0 ]; then
    run_logged ./cook.py verilator-testharness-run-testlist \
      --target "${TIER_CONFIG}" \
      --testlist "${TIER_TESTLIST}" \
      --tandem-enabled \
      --iss-timeout "${TIER_ISS_TIMEOUT}"
    record_rc "$?"
  fi
elif [ "${rc}" -eq 0 ] && [ "${TIER_MODE}" = "testlist" ]; then
  if [[ "${TIER_SIMULATOR}" == *"veri-testharness"* ]]; then
    source_logged verif/regress/install-verilator.sh
    record_rc "$?"
  fi

  if [ "${rc}" -eq 0 ]; then
    source_logged verif/regress/install-spike.sh
    record_rc "$?"
  fi

  if [ "${rc}" -eq 0 ] && [ -n "${TIER_INSTALL_SCRIPT}" ]; then
    source_logged "verif/regress/${TIER_INSTALL_SCRIPT}.sh"
    record_rc "$?"
  fi

  if [ "${rc}" -eq 0 ]; then
    cva6_cmd=(
      python3 cva6.py
      "--testlist=${TIER_TESTLIST}"
      --target "${TIER_CONFIG}"
      --iss_yaml=cva6.yaml
      "--iss=${TIER_SIMULATOR}"
      "--issrun_opts=+tb_performance_mode+debug_disable=1+UVM_VERBOSITY=UVM_NONE"
    )

    if [ -n "${TIER_LINKER}" ]; then
      cva6_cmd+=("--linker=${TIER_LINKER}")
    fi

    if [ -n "${TIER_TEST_NAME}" ]; then
      cva6_cmd+=(--test "${TIER_TEST_NAME}")
    fi

    pushd verif/sim > /dev/null || rc=$?
    if [ "${rc}" -eq 0 ]; then
      run_logged "${cva6_cmd[@]}"
      record_rc "$?"
    fi
    popd > /dev/null || true
  fi
elif [ "${rc}" -eq 0 ]; then
  if [ -n "${TIER_HWCONFIG_OPTS}" ]; then
    export DV_HWCONFIG_OPTS="${TIER_HWCONFIG_OPTS}"
  fi

  run_logged env \
    DV_SIMULATORS="${TIER_SIMULATOR}" \
    DV_TARGET="${TIER_CONFIG}" \
    bash -e "verif/regress/${TIER_TESTCASE}.sh"
  record_rc "$?"
fi

collect_reports

if [ "${rc}" -eq 0 ]; then
  if [ "${TIER_MODE}" = "cook-testlist" ]; then
    if ! find "build/${TIER_CONFIG}/simulation/sim_verilator_testharness" \
      -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
      append_failure "ERROR: cook-testlist mode produced no simulation results."
      rc=1
    fi
  elif ! compgen -G "verif/sim/out*" > /dev/null; then
    append_failure "ERROR: ${TIER_NAME} job produced no verif/sim/out* results."
    rc=1
  fi
fi

scan_rc=0
scan_for_failures || scan_rc=1
scan_iss_traces || scan_rc=1
if [ "${rc}" -eq 0 ] && [ "${scan_rc}" -ne 0 ]; then
  rc=1
fi
if [ "${rc}" -ne 0 ] && [ ! -s "${FAILURE_SUMMARY}" ]; then
  append_failure "Regression exited with code ${rc}; inspect run.log for details."
fi

write_metadata
echo "${rc}" > "${EXIT_CODE_FILE}"
exit "${rc}"
