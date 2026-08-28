#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
coverage_dir="${COVERAGE_DIR:-$repo_root/coverage}"
output_log="$(mktemp "${TMPDIR:-/tmp}/combineextensions-test.XXXXXX")"

cleanup() {
  rm -f "$output_log"
}

trap cleanup EXIT

cd "$repo_root"
mkdir -p "$coverage_dir"
export LLVM_PROFILE_FILE="$coverage_dir/profile-%p.profraw"

set +e
swift test --enable-code-coverage --show-codecov-path 2>&1 | tee "$output_log"
test_status="${PIPESTATUS[0]}"
set -e

if [[ "$test_status" -ne 0 ]]; then
  echo "Tests failed; coverage report was not exported." >&2
  exit "$test_status"
fi

source_report="$(sed -nE 's#^(/.*\.json)$#\1#p' "$output_log" | tail -n 1)"

if [[ -z "$source_report" || ! -f "$source_report" ]]; then
  echo "Tests passed, but SwiftPM did not report a coverage JSON file." >&2
  exit 1
fi

destination="$coverage_dir/coverage.json"
cp "$source_report" "$destination"
echo "Coverage report: $destination"
