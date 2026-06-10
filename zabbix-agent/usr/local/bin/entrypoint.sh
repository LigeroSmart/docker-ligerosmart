#!/bin/sh
set -eu

DOCKER_ENTRYPOINT="${DOCKER_ENTRYPOINT:-/usr/bin/docker-entrypoint.sh}"

# ---------------------------------------------------------------------------
# MySQL / MariaDB
#
# Configurado quando MYSQL_HOST está definido, ou quando o PostgreSQL não está
# em uso (mantém o comportamento histórico do container). É pulado apenas
# quando POSTGRES_HOST está definido e MYSQL_HOST não — agente só PostgreSQL.
# ---------------------------------------------------------------------------
if [ -n "${MYSQL_HOST:-}" ] || [ -z "${POSTGRES_HOST:-}" ]; then
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
    echo "password=\"${MYSQL_PASSWORD}\""
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
fi

# ---------------------------------------------------------------------------
# PostgreSQL
#
# Configurado quando POSTGRES_HOST está definido. Gera um service file libpq
# (~/.pg_service.conf, análogo ao .my.cnf) com os parâmetros de conexão e um
# ~/.pgpass com a senha. Os scripts de monitoramento usam service=<nome>.
# ---------------------------------------------------------------------------
if [ -n "${POSTGRES_HOST:-}" ]; then
  PG_SERVICE_PATH="${PG_SERVICE_PATH:-/var/lib/zabbix/.pg_service.conf}"
  PGPASS_PATH="${PGPASS_PATH:-/var/lib/zabbix/.pgpass}"
  POSTGRES_SERVICE_NAME="${POSTGRES_SERVICE_NAME:-ligerosmart}"
  POSTGRES_PORT="${POSTGRES_PORT:-5432}"
  POSTGRES_SSL_MODE="${POSTGRES_SSL_MODE:-disable}"

  required_vars="POSTGRES_HOST POSTGRES_USER POSTGRES_PASSWORD POSTGRES_DATABASE"
  for var in $required_vars; do
    eval "value=\${$var:-}"
    if [ -z "$value" ]; then
      echo "[entrypoint] erro: variável obrigatória '$var' não definida" >&2
      exit 1
    fi
  done

  # Mapeia sinônimos amigáveis para os valores de sslmode do libpq.
  case "$POSTGRES_SSL_MODE" in
    DISABLED|disabled|0|false|FALSE|no|NO)
      pg_sslmode="disable"
      ;;
    REQUIRED|required|1|true|TRUE|yes|YES)
      pg_sslmode="require"
      ;;
    *)
      pg_sslmode="$POSTGRES_SSL_MODE"
      ;;
  esac

  mkdir -p "$(dirname "$PG_SERVICE_PATH")" "$(dirname "$PGPASS_PATH")"
  umask 077

  {
    echo "[${POSTGRES_SERVICE_NAME}]"
    echo "host=${POSTGRES_HOST}"
    echo "port=${POSTGRES_PORT}"
    echo "dbname=${POSTGRES_DATABASE}"
    echo "user=${POSTGRES_USER}"
    echo "sslmode=${pg_sslmode}"

    [ -n "${POSTGRES_CONNECT_TIMEOUT:-}" ] && echo "connect_timeout=${POSTGRES_CONNECT_TIMEOUT}"
    [ -n "${POSTGRES_SSL_CA:-}" ] && echo "sslrootcert=${POSTGRES_SSL_CA}"
    [ -n "${POSTGRES_SSL_CERT:-}" ] && echo "sslcert=${POSTGRES_SSL_CERT}"
    [ -n "${POSTGRES_SSL_KEY:-}" ] && echo "sslkey=${POSTGRES_SSL_KEY}"
  } > "$PG_SERVICE_PATH"

  chmod 600 "$PG_SERVICE_PATH"

  # Formato do .pgpass: host:port:database:user:password
  # Os campos precisam escapar '\' e ':' com barra invertida.
  pgpass_escape() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/:/\\:/g'
  }

  {
    printf '%s:%s:%s:%s:%s\n' \
      "$(pgpass_escape "$POSTGRES_HOST")" \
      "$(pgpass_escape "$POSTGRES_PORT")" \
      "$(pgpass_escape "$POSTGRES_DATABASE")" \
      "$(pgpass_escape "$POSTGRES_USER")" \
      "$(pgpass_escape "$POSTGRES_PASSWORD")"
  } > "$PGPASS_PATH"

  chmod 600 "$PGPASS_PATH"

  if [ -n "${ZABBIX_RUN_USER:-}" ]; then
    chown "$ZABBIX_RUN_USER":"$ZABBIX_RUN_USER" "$PG_SERVICE_PATH" "$PGPASS_PATH" 2>/dev/null || true
  elif id zabbix >/dev/null 2>&1; then
    chown zabbix:zabbix "$PG_SERVICE_PATH" "$PGPASS_PATH" 2>/dev/null || true
  fi

  echo "[entrypoint] arquivos .pg_service.conf e .pgpass criados em $(dirname "$PG_SERVICE_PATH")"
fi

"$DOCKER_ENTRYPOINT" "$@"
