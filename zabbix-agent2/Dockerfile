# Migração para Zabbix Agent 2 (Go) — UserParameters do v1 são 100% compatíveis.
# Ganhos: plugins nativos (PostgreSQL, MySQL, Docker, Redis, etc.) e active checks com cache persistente.
FROM zabbix/zabbix-agent2:alpine-6.4-latest

USER root

RUN apk add mysql-client postgresql-client

COPY --chown=zabbix:zabbix etc /etc
COPY --chown=zabbix:zabbix var /var
COPY usr /usr
RUN chmod +x /usr/local/bin/*

COPY healthcheck.sh /healthcheck.sh

USER zabbix

HEALTHCHECK  --interval=1m --timeout=10s \
  CMD /healthcheck.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]

CMD [ "/usr/sbin/zabbix_agent2", "--foreground", "-c", "/etc/zabbix/zabbix_agent2.conf" ]
