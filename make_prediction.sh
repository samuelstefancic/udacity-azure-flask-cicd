#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
base_url=${1:-http://127.0.0.1:8000}

curl --fail-with-body --silent --show-error --max-time 30 \
  -H 'Content-Type: application/json' \
  --data-binary "@$project_dir/sample-prediction.json" \
  "${base_url%/}/predict"
