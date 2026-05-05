FROM zabbix/zabbix-agent:alpine-7.0-latest

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

CMD [ "/usr/sbin/zabbix_agentd", "--foreground", "-c", "/etc/zabbix/zabbix_agentd.conf" ]