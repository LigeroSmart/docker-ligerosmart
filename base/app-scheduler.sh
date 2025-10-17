#!/bin/bash

export START_SCHEDULER=${START_SCHEDULER:-1}
export DEBUG_MODE=${DEBUG_MODE:-0}
export APP_USER=${APP_USER:-otrs}
export SMTPSERVER=${SMTPSERVER:-mail}
export SMTPPORT=${SMTPPORT:-25}
export EMAIL=${EMAIL:-"$APP_USER@localhost"}
export EMAILPASSWORD=${EMAILPASSWORD:-"passw0rd"}

_term() {
    echo 'Terminating scheduler'
    su -c "otrs.Daemon.pl stop" $APP_USER 
}

trap _term SIGINT SIGTERM

su -c "otrs.Daemon.pl start" $APP_USER 
Cron.sh start $APP_USER  
/usr/sbin/cron -f -L 15 &
wait "$!"