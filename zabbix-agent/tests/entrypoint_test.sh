#!/usr/bin/env bash
#
# Testes do contrato de geração de credenciais do entrypoint.sh.
# Cobre a detecção de POSTGRES_HOST e a opcionalidade do MySQL/MariaDB.
#
# Não exige servidores de banco: valida apenas os arquivos de credencial
# gerados (.my.cnf, .pg_service.conf, .pgpass).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENTRYPOINT="$SCRIPT_DIR/../usr/local/bin/entrypoint.sh"

fail=0
pass=0

assert() {
  # assert <descrição> <comando-de-teste...>
  local desc="$1"; shift
  if "$@"; then
    pass=$((pass + 1))
    printf '  ok   - %s\n' "$desc"
  else
    fail=$((fail + 1))
    printf '  FAIL - %s\n' "$desc"
  fi
}

file_contains() { grep -qF -- "$2" "$1"; }

# Executa o entrypoint num ambiente limpo (env -i) com paths em diretório temp.
# Aceita pares VAR=valor como argumentos. Retorna o código de saída do entrypoint.
run_entrypoint() {
  local tmp="$1"; shift
  env -i \
    PATH="$PATH" \
    HOME="$tmp" \
    DOCKER_ENTRYPOINT=/bin/true \
    MYCNF_PATH="$tmp/.my.cnf" \
    PG_SERVICE_PATH="$tmp/.pg_service.conf" \
    PGPASS_PATH="$tmp/.pgpass" \
    "$@" \
    sh "$ENTRYPOINT"
}

echo "== Caso A: somente PostgreSQL (POSTGRES_HOST presente, MYSQL_HOST ausente) =="
TMP="$(mktemp -d)"
run_entrypoint "$TMP" \
  POSTGRES_HOST=pg.example \
  POSTGRES_USER=zbx \
  POSTGRES_PASSWORD='p:a\ss' \
  POSTGRES_DATABASE=ligero \
  >/dev/null 2>&1
assert "gera .pg_service.conf" test -f "$TMP/.pg_service.conf"
assert "service file tem host" file_contains "$TMP/.pg_service.conf" "host=pg.example"
assert "service file tem dbname" file_contains "$TMP/.pg_service.conf" "dbname=ligero"
assert "service file tem user" file_contains "$TMP/.pg_service.conf" "user=zbx"
assert "service file tem porta padrão 5432" file_contains "$TMP/.pg_service.conf" "port=5432"
assert "service file tem sslmode padrão disable" file_contains "$TMP/.pg_service.conf" "sslmode=disable"
assert "gera .pgpass" test -f "$TMP/.pgpass"
assert "pgpass com host:port:db:user e senha escapada" \
  file_contains "$TMP/.pgpass" 'pg.example:5432:ligero:zbx:p\:a\\ss'
assert "NÃO gera .my.cnf (MySQL pulado)" test ! -f "$TMP/.my.cnf"
rm -rf "$TMP"

echo "== Caso B: somente MySQL (comportamento atual preservado) =="
TMP="$(mktemp -d)"
run_entrypoint "$TMP" \
  MYSQL_HOST=db \
  MYSQL_USER=root \
  MYSQL_PASSWORD=secret \
  MYSQL_DATABASE=ligero \
  >/dev/null 2>&1
assert "gera .my.cnf" test -f "$TMP/.my.cnf"
assert "my.cnf tem host" file_contains "$TMP/.my.cnf" "host=db"
assert "NÃO gera .pg_service.conf" test ! -f "$TMP/.pg_service.conf"
assert "NÃO gera .pgpass" test ! -f "$TMP/.pgpass"
rm -rf "$TMP"

echo "== Caso C: MySQL e PostgreSQL simultâneos =="
TMP="$(mktemp -d)"
run_entrypoint "$TMP" \
  MYSQL_HOST=db \
  MYSQL_USER=root \
  MYSQL_PASSWORD=secret \
  MYSQL_DATABASE=ligero \
  POSTGRES_HOST=pg.example \
  POSTGRES_USER=zbx \
  POSTGRES_PASSWORD=pw \
  POSTGRES_DATABASE=ligero \
  >/dev/null 2>&1
assert "gera .my.cnf" test -f "$TMP/.my.cnf"
assert "gera .pg_service.conf" test -f "$TMP/.pg_service.conf"
rm -rf "$TMP"

echo "== Caso D: PostgreSQL com variável obrigatória ausente falha =="
TMP="$(mktemp -d)"
run_entrypoint "$TMP" \
  POSTGRES_HOST=pg.example \
  POSTGRES_PASSWORD=pw \
  POSTGRES_DATABASE=ligero \
  >/dev/null 2>&1
rc=$?
assert "entrypoint sai com erro (POSTGRES_USER ausente)" test "$rc" -ne 0
assert "NÃO gera .pg_service.conf em caso de erro" test ! -f "$TMP/.pg_service.conf"
rm -rf "$TMP"

echo "== Caso E: mapeamento de POSTGRES_SSL_MODE =="
TMP="$(mktemp -d)"
run_entrypoint "$TMP" \
  POSTGRES_HOST=pg.example \
  POSTGRES_USER=zbx \
  POSTGRES_PASSWORD=pw \
  POSTGRES_DATABASE=ligero \
  POSTGRES_SSL_MODE=REQUIRED \
  >/dev/null 2>&1
assert "REQUIRED mapeia para sslmode=require" file_contains "$TMP/.pg_service.conf" "sslmode=require"
rm -rf "$TMP"

TMP="$(mktemp -d)"
run_entrypoint "$TMP" \
  POSTGRES_HOST=pg.example \
  POSTGRES_USER=zbx \
  POSTGRES_PASSWORD=pw \
  POSTGRES_DATABASE=ligero \
  POSTGRES_SSL_MODE=verify-full \
  >/dev/null 2>&1
assert "valor libpq direto (verify-full) é repassado" file_contains "$TMP/.pg_service.conf" "sslmode=verify-full"
rm -rf "$TMP"

echo
echo "Resultado: $pass passou, $fail falhou"
[ "$fail" -eq 0 ]
