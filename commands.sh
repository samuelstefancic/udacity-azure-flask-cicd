#!/usr/bin/env bash
set -euo pipefail

project_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
action=${1:?Usage: ./commands.sh bootstrap|bootstrap-legacy|url|predict|logs RESOURCE_GROUP APP_NAME}
group=${2:?Enter the Azure resource group.}
app=${3:?Enter the Azure App Service name.}

app_url() {
  local hostname
  hostname=$(az webapp show -g "$group" -n "$app" --query defaultHostName -o tsv)
  [[ -n $hostname ]] || { echo 'Azure did not return a hostname.' >&2; return 1; }
  printf 'https://%s\n' "$hostname"
}

case "$action" in
  bootstrap|bootstrap-legacy)
    : "${AZURE_SKU:?Set AZURE_SKU to a tier allowed by your lab before bootstrapping.}"
    staging=$(mktemp -d)
    trap 'rm -rf -- "$staging"' EXIT
    revision=$(git -C "$project_dir" rev-parse HEAD)
    python3 "$project_dir/package_app.py" "$staging/app.zip" "$revision"
    if [[ $action == bootstrap-legacy ]]; then
      python3 -m zipfile -e "$staging/app.zip" "$staging/site"
      cd "$staging/site"
      az webapp up -n "$app" -g "$group" --sku "$AZURE_SKU" --runtime 'PYTHON:3.12' --logs
    else
      : "${AZURE_PLAN:?Set AZURE_PLAN to the name of your Linux App Service plan.}"
      region=${AZURE_LOCATION:-$(az group show -n "$group" --query location -o tsv)}
      existing_plans=$(az appservice plan list -g "$group" --query '[].name' -o tsv)
      if ! grep -Fxiq -- "$AZURE_PLAN" <<< "$existing_plans"; then
        az appservice plan create -g "$group" -n "$AZURE_PLAN" -l "$region" --is-linux --sku "$AZURE_SKU" -o none
      fi
      existing_apps=$(az webapp list -g "$group" --query '[].name' -o tsv)
      if ! grep -Fxiq -- "$app" <<< "$existing_apps"; then
        az webapp create -g "$group" -p "$AZURE_PLAN" -n "$app" --runtime 'PYTHON:3.12' --basic-auth Disabled -o none
      fi
    fi
    az webapp update -g "$group" -n "$app" --https-only true -o none
    az webapp config appsettings set -g "$group" -n "$app" \
      --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true -o none
    az webapp config set -g "$group" -n "$app" \
      --startup-file 'gunicorn --bind=0.0.0.0:8000 --access-logfile - --error-logfile - app:app' -o none
    if [[ $action == bootstrap ]]; then
      az webapp deploy -g "$group" -n "$app" --src-path "$staging/app.zip" \
        --type zip --track-status true --timeout 360000 -o none
    fi
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
