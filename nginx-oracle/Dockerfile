FROM ligero/ligerosmart:6.1-nginx

COPY --chown=root:root etc /etc
COPY --chown=root:root app-run-oracle-support.sh /

RUN sudo apt-get update \
    && sudo apt-get install -y \
       libaio1 \
       build-essential \
    && cd /tmp \
    && curl --silent --remote-name --location https://addons.ligerosmart.org/packages/oracle/oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb \
    && curl --silent --remote-name --location https://addons.ligerosmart.org/packages/oracle/oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb \
    && curl --silent --remote-name --location https://addons.ligerosmart.org/packages/oracle/oracle-instantclient12.1-sqlplus_12.1.0.2.0-2_amd64.deb \
    && dpkg -i oracle-instantclient12.1-basic_12.1.0.2.0-2_amd64.deb \
    && dpkg -i oracle-instantclient12.1-devel_12.1.0.2.0-2_amd64.deb \
    && dpkg -i oracle-instantclient12.1-sqlplus_12.1.0.2.0-2_amd64.deb \
    && rm -rf /tmp/*.deb \
    && cpanm --quiet --notest DBD::Oracle \
    && apt remove build-essential -y \
    && apt autoremove -y \
    && rm -rf /var/lib/apt/lists/* 

CMD /app-run-oracle-support.sh

ENV START_WEBSERVER=1 \
    START_SCHEDULER=1
