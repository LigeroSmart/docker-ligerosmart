#!/bin/bash

# exit on error
set -o errexit

# MySQL/MariaDB: verificado quando ativo (MYSQL_HOST definido, ou PostgreSQL
# fora de uso). Pulado apenas no modo só-PostgreSQL.
if [ -n "${MYSQL_HOST:-}" ] || [ -z "${POSTGRES_HOST:-}" ]; then
  ping -c 1 $MYSQL_HOST > /dev/null

  mariadb --skip-ssl -BN -h $MYSQL_HOST -u $MYSQL_USER -p$MYSQL_PASSWORD -e '/* ping */  SELECT 1' $MYSQL_DATABASE > /dev/null
fi

# PostgreSQL: verificado quando POSTGRES_HOST está definido.
if [ -n "${POSTGRES_HOST:-}" ]; then
  ping -c 1 $POSTGRES_HOST > /dev/null

  PGPASSWORD="$POSTGRES_PASSWORD" psql -h "$POSTGRES_HOST" -p "${POSTGRES_PORT:-5432}" -U "$POSTGRES_USER" -d "$POSTGRES_DATABASE" -tAc '/* ping */ SELECT 1' > /dev/null
fi
