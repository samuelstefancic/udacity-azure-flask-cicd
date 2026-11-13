#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
app_url=${1:?Usage: ./make_predict_azure_app.sh https://app-hostname}
[[ $app_url == https://* ]] || { echo 'Expected an HTTPS URL.' >&2; exit 2; }
printf 'POST %s/predict\n' "${app_url%/}" >&2
exec "$project_dir/make_prediction.sh" "$app_url"
