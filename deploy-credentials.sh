#!/usr/bin/env bash

set -eou pipefail

SECRET=$(aws secretsmanager get-secret-value --secret-id conduit/db/credentials --query SecretString --output text)

export PROD_DB_NAME=$(echo "$SECRET" | jq -r .DB_NAME)
export PROD_DB_USERNAME=$(echo "$SECRET" | jq -r .DB_USER)
export PROD_DB_PASSWORD=$(echo "$SECRET" | jq -r .DB_PASSWORD)
export DOCKER_HUB_USER="$1" BACKEND_IMAGE="$2" FRONTEND_IMAGE="$3" BUILD_NUMBER="$4"

docker compose pull
docker compose up -d