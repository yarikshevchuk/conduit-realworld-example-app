#!/bin/sh
set -e

SECRET=$(
  aws secretsmanager get-secret-value \
  --secret-id conduit/db/credentials \
  --query SecretString --output text
)

export PROD_DB_USERNAME=$(echo "$SECRET" | jq -r .DB_USER)
export PROD_DB_PASSWORD=$(echo "$SECRET" | jq -r .DB_PASSWORD)
export PROD_DB_NAME=$(echo "$SECRET" | jq -r .DB_NAME)

exec "$@"