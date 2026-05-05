#!/bin/sh
set -eu

MYCNF_PATH="${MYCNF_PATH:-/var/lib/zabbix/.my.cnf}"
MYSQL_PORT="${MYSQL_PORT:-3306}"
MYSQL_SSL_MODE="${MYSQL_SSL_MODE:-DISABLED}"
MYSQL_DEFAULT_GROUP_SUFFIX="${MYSQL_DEFAULT_GROUP_SUFFIX:-}"

required_vars="MYSQL_HOST MYSQL_USER MYSQL_PASSWORD MYSQL_DATABASE"
for var in $required_vars; do
  eval "value=\${$var:-}"
  if [ -z "$value" ]; then
    echo "[entrypoint] erro: variável obrigatória '$var' não definida" >&2
    exit 1
  fi
done

mkdir -p "$(dirname "$MYCNF_PATH")"
umask 077

{
  echo "[client]"
  echo "host=${MYSQL_HOST}"
  echo "user=${MYSQL_USER}"
  echo "password=${MYSQL_PASSWORD}"
  echo "database=${MYSQL_DATABASE}"
  echo "port=${MYSQL_PORT}"

  case "$MYSQL_SSL_MODE" in
    DISABLED|disabled|0|false|FALSE|no|NO)
      echo "ssl=0"
      ;;
    REQUIRED|required|1|true|TRUE|yes|YES)
      echo "ssl=1"
      ;;
    *)
      echo "ssl=${MYSQL_SSL_MODE}"
      ;;
  esac

  [ -n "$MYSQL_DEFAULT_GROUP_SUFFIX" ] && echo "default-group-suffix=${MYSQL_DEFAULT_GROUP_SUFFIX}"
  [ -n "${MYSQL_SOCKET:-}" ] && echo "socket=${MYSQL_SOCKET}"
  [ -n "${MYSQL_PROTOCOL:-}" ] && echo "protocol=${MYSQL_PROTOCOL}"
  [ -n "${MYSQL_CHARSET:-}" ] && echo "default-character-set=${MYSQL_CHARSET}"
  [ -n "${MYSQL_CONNECT_TIMEOUT:-}" ] && echo "connect-timeout=${MYSQL_CONNECT_TIMEOUT}"
  [ -n "${MYSQL_INIT_COMMAND:-}" ] && echo "init-command=${MYSQL_INIT_COMMAND}"
  [ -n "${MYSQL_SSL_CA:-}" ] && echo "ssl-ca=${MYSQL_SSL_CA}"
  [ -n "${MYSQL_SSL_CERT:-}" ] && echo "ssl-cert=${MYSQL_SSL_CERT}"
  [ -n "${MYSQL_SSL_KEY:-}" ] && echo "ssl-key=${MYSQL_SSL_KEY}"
  [ -n "${MYSQL_SSL_CIPHER:-}" ] && echo "ssl-cipher=${MYSQL_SSL_CIPHER}"
} > "$MYCNF_PATH"

chmod 600 "$MYCNF_PATH"

if [ -n "${ZABBIX_RUN_USER:-}" ]; then
  chown "$ZABBIX_RUN_USER":"$ZABBIX_RUN_USER" "$MYCNF_PATH" 2>/dev/null || true
elif id zabbix >/dev/null 2>&1; then
  chown zabbix:zabbix "$MYCNF_PATH" 2>/dev/null || true
fi

echo "[entrypoint] arquivo .my.cnf criado em $MYCNF_PATH"

if [ "$#" -gt 0 ]; then
  exec "$@"
fi

exec /usr/sbin/zabbix_agentd -f -c /etc/zabbix/zabbix_agentd.conf