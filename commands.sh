#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
action=${1:?Usage: ./commands.sh bootstrap|url|predict|logs RESOURCE_GROUP APP_NAME}
group=${2:?Enter the Azure resource group.}
app=${3:?Enter the Azure App Service name.}

app_url() {
  local hostname
  hostname=$(az webapp show -g "$group" -n "$app" --query defaultHostName -o tsv)
  [[ -n $hostname ]] || { echo 'Azure did not return a hostname.' >&2; return 1; }
  printf 'https://%s\n' "$hostname"
}

case "$action" in
  bootstrap)
    : "${AZURE_SKU:?Set AZURE_SKU to a tier allowed by your lab before bootstrapping.}"
    staging=$(mktemp -d)
    trap 'rm -rf -- "$staging"' EXIT
    revision=$(git -C "$project_dir" rev-parse HEAD)
    python3 "$project_dir/package_app.py" "$staging/app.zip" "$revision"
    python3 -m zipfile -e "$staging/app.zip" "$staging/site"
    cd "$staging/site"
    az webapp up -n "$app" -g "$group" --sku "$AZURE_SKU" --runtime 'PYTHON:3.12' --logs
    az webapp update -g "$group" -n "$app" --https-only true -o none
    az webapp config appsettings set -g "$group" -n "$app" \
      --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true -o none
    az webapp config set -g "$group" -n "$app" \
      --startup-file 'gunicorn --bind=0.0.0.0:8000 --access-logfile - --error-logfile - app:app' -o none
    app_url
    ;;
  url)
    app_url
    ;;
  predict)
    url=$(app_url)
    "$project_dir/make_predict_azure_app.sh" "$url"
    ;;
  logs)
    az webapp log config -g "$group" -n "$app" --docker-container-logging filesystem -o none
    az webapp log tail -g "$group" -n "$app"
    ;;
  *)
    echo "Unknown action: $action" >&2
    exit 2
    ;;
esac
