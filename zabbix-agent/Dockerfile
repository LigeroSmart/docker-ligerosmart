FROM zabbix/zabbix-agent:alpine-latest

USER root

RUN apk add mysql-client postgresql-client

COPY --chown=zabbix:zabbix etc /etc
COPY --chown=zabbix:zabbix var /var

COPY healthcheck.sh /healthcheck.sh

USER zabbix

HEALTHCHECK  --interval=1m --timeout=10s \
  CMD /healthcheck.sh
