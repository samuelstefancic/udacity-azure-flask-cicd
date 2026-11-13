# Initial App Service deployment

Run these commands from the repository root in Azure Cloud Shell. Use the active Udacity subscription. The example targets the original lab resource group and provisions a Linux Free F1 plan.

The starter command `az webapp up` failed on Azure CLI 2.91.0 during location discovery. The following sequence successfully created the plan and Web App and deployed the ZIP.

```bash
RESOURCE_GROUP=Azuredevops
PLAN_NAME=udacity-flask-f1
APP_NAME=udacity-flask-cicd-b91c16b
stage=$(mktemp -d)
python package_app.py "$stage/app.zip" "$(git rev-parse HEAD)"

az appservice plan create -g "$RESOURCE_GROUP" -n "$PLAN_NAME" -l eastus --is-linux --sku F1
az webapp create -g "$RESOURCE_GROUP" -p "$PLAN_NAME" -n "$APP_NAME" \
  --runtime PYTHON:3.12 --basic-auth Disabled \
  --startup-file 'gunicorn --bind=0.0.0.0:8000 --access-logfile - --error-logfile - app:app'
az webapp update -g "$RESOURCE_GROUP" -n "$APP_NAME" --https-only true -o none
az webapp config appsettings set -g "$RESOURCE_GROUP" -n "$APP_NAME" \
  --settings SCM_DO_BUILD_DURING_DEPLOYMENT=true -o none
az webapp deploy -g "$RESOURCE_GROUP" -n "$APP_NAME" --src-path "$stage/app.zip" \
  --type zip --track-status true --timeout 360000
```

Run `./commands.sh predict "$RESOURCE_GROUP" "$APP_NAME"` to verify the HTTPS endpoint. The initial response was HTTP 200 with `{"prediction":[2.431574790057212]}` and `X-Revision` matching commit `b91c16b`.
