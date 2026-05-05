#!/bin/bash
set -euo pipefail

case "$1" in
  count_mail_queue)
    QUERY="SELECT count(*) FROM mail_queue"
    ;;
  count_users)
    QUERY="SELECT count(*) FROM users WHERE valid_id=1"
    ;;
  count_sessions_users)
    QUERY="SELECT count(DISTINCT session_id) FROM sessions WHERE data_key='UserType' AND data_value='User'"
    ;;
  *)
    echo "ZBX_NOTSUPPORTED"
    exit 1
    ;;
esac

/usr/bin/mariadb --skip-ssl -BN -e "$QUERY"