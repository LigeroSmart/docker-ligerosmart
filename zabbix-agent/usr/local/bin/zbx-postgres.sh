#!/usr/bin/env bash

# Fail fast
set -euo pipefail

# Lê as credenciais do service file libpq (~/.pg_service.conf) e a senha do
# ~/.pgpass, ambos gerados pelo entrypoint quando POSTGRES_HOST está definido.
export PGSERVICEFILE="${PGSERVICEFILE:-/var/lib/zabbix/.pg_service.conf}"
export PGPASSFILE="${PGPASSFILE:-/var/lib/zabbix/.pgpass}"
PG_SERVICE_NAME="${POSTGRES_SERVICE_NAME:-ligerosmart}"

QUERY="$1"

# -t: sem cabeçalho | -A: sem alinhamento | -F: separador TAB (equivale ao -BN
# do mariadb) | -X: ignora ~/.psqlrc | -q: silencioso
/usr/bin/psql "service=${PG_SERVICE_NAME}" -X -q -t -A -F$'\t' -c "$QUERY"
