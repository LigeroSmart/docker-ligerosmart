#!/usr/bin/env bash
#
# Testes do contrato do UserParameter count_scheduler_task_old (MariaDB e
# PostgreSQL): o limite de horas vem do parâmetro da chave, com default 4.
#
# Não exige agente nem banco: lê a linha real do .conf, substitui $1 como o
# agente Zabbix faz e roda o zbx-scheduler-task-old.sh real num diretório temp,
# ao lado de stubs do zbx-mariadb.sh/zbx-postgres.sh que imprimem "<nome>|<query>".

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONF_DIR="$(echo "$SCRIPT_DIR"/../etc/zabbix/zabbix_agent*.d)"

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

contains() { case "$1" in *"$2"*) return 0 ;; *) return 1 ;; esac; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

BIN="$TMP/bin"
mkdir -p "$BIN"
cp "$SCRIPT_DIR/../usr/local/bin/zbx-scheduler-task-old.sh" "$BIN/"
for wrapper in zbx-mariadb.sh zbx-postgres.sh; do
  printf '#!/bin/sh\nprintf "%%s|%%s\\n" "$(basename "$0")" "$1"\n' > "$BIN/$wrapper"
  chmod +x "$BIN/$wrapper"
done

# Executa o comando do UserParameter <chave> do arquivo <conf> com <parâmetro>.
# Preenche as globais out (stdout), err (stderr) e rc (código de saída).
run_key() {
  local conf="$1" key="$2" param="$3" cmd
  cmd="$(grep -F -- "UserParameter=${key}[*]," "$CONF_DIR/$conf")"
  cmd="${cmd#*,}"
  cmd="${cmd//'$1'/$param}"
  cmd="${cmd//\/usr\/local\/bin/$BIN}"
  out="$(sh -c "$cmd" 2>"$TMP/err")"
  rc=$?
  err="$(cat "$TMP/err")"
}

# check_key <conf> <chave> <wrapper esperado> <formato do intervalo, %s = horas>
check_key() {
  local conf="$1" key="$2" wrapper="$3" fmt="$4" invalid

  echo "== $key ($conf) =="

  run_key "$conf" "$key" ""
  assert "consulta via $wrapper" contains "$out" "$wrapper|SELECT count(*) FROM scheduler_task WHERE"
  assert "sem parâmetro usa o default de 4 horas" contains "$out" "$(printf "$fmt" 4)"

  run_key "$conf" "$key" "12"
  assert "parâmetro 12 vira 12 horas" contains "$out" "$(printf "$fmt" 12)"

  for invalid in "abc" "1.5" "4 hour -- "; do
    run_key "$conf" "$key" "$invalid"
    assert "parâmetro '$invalid' sai com erro" test "$rc" -ne 0
    assert "parâmetro '$invalid' não executa SQL" test -z "$out"
    assert "parâmetro '$invalid' informa o valor inválido" contains "$err" "horas invalidas: $invalid"
  done
}

check_key ligerosmart.conf ligerosmart.count_scheduler_task_old zbx-mariadb.sh "INTERVAL %s HOUR"
check_key ligerosmart-pg.conf ligerosmart.pg.count_scheduler_task_old zbx-postgres.sh "INTERVAL '%s hour'"

echo
echo "Resultado: $pass passou, $fail falhou"
[ "$fail" -eq 0 ]
