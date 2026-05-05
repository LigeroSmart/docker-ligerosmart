#!/usr/bin/env bash

# Fail fast
set -euo pipefail

# Config (ou usar /root/.my.cnf)
MYSQL_HOST="${MYSQL_HOST:-database}"
MYSQL_USER="${MYSQL_USER:-root}"
MYSQL_PASSWORD="${MYSQL_PASSWORD}"
MYSQL_DATABASE="${MYSQL_DATABASE:-ligerosmart}"

QUERY="$1"

# Execução segura
/usr/bin/mariadb --skip-ssl -BN \
  -h "$MYSQL_HOST" \
  -u "$MYSQL_USER" \
  -p"$MYSQL_PASSWORD" \
  -e "$QUERY" \
  "$MYSQL_DATABASE"