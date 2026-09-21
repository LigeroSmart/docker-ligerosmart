#!/usr/bin/env bash

# Fail fast
set -euo pipefail

# Conta as linhas de scheduler_task mais antigas que N horas.
# Uso: zbx-scheduler-task-old.sh <mariadb|postgres> [horas]
DB="$1"
HOURS="${2:-4}"

# O valor vem do parâmetro da chave do item no Zabbix e entra no SQL: só inteiro.
case "$HOURS" in
  *[!0-9]*)
    echo "horas invalidas: $HOURS" >&2
    exit 1
    ;;
esac

BIN_DIR="$(dirname "$0")"

case "$DB" in
  mariadb)
    "$BIN_DIR/zbx-mariadb.sh" "SELECT count(*) FROM scheduler_task WHERE create_time <= DATE_SUB(NOW(), INTERVAL $HOURS HOUR)"
    ;;
  postgres)
    "$BIN_DIR/zbx-postgres.sh" "SELECT count(*) FROM scheduler_task WHERE create_time <= NOW() - INTERVAL '$HOURS hour'"
    ;;
esac
