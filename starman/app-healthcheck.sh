#!/bin/bash
#set -x
HEARTBEAT_FILE=/tmp/healthcheck_on
HEARTBEAT_INTERVAL=${HEARTBEAT_INTERVAL:-4} # minutes

if [ "$(pgrep -f httpserver.pl)" ]; then
  exit 0
fi

if [ ! -f "$HEARTBEAT_FILE" ]; then
  touch $HEARTBEAT_FILE
  exit 0
fi

if test -z `find "$HEARTBEAT_FILE" -mmin +$HEARTBEAT_INTERVAL`; then
  # heartbeat ok
  exit 0
fi

# WEBSERVER test - Starman direto na porta 80
if [ "$START_WEBSERVER" == "1" ]; then
    healthcheck_webserver_error=0
    curl -m 50 -f -s http://127.0.0.1/otrs/index.pl?healthcheck -o /dev/null || healthcheck_webserver_error=1
    if [ "$healthcheck_webserver_error" -eq 1 ]; then
      echo "$0: webserver is not responding"
      exit 1
    fi
fi;

# SCHEDULER test
if [ "$START_SCHEDULER" == "1" ]; then 
  if [ -z "$(pgrep -f otrs.Daemon.pl)" ]; then
    echo "$0: otrs.Daemon.pl is not running"
    exit 1
  fi
fi;

touch $HEARTBEAT_FILE


# returns ok
exit 0
