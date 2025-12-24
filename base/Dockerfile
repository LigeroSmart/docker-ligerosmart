FROM fasibio/docker-gosendmail:latest AS gosendmail

FROM ubuntu:20.04 AS base

ARG RELEASE_TAG

ENV RELEASE_TAG $RELEASE_TAG 

ENV CODE_REPOSITORY="https://github.com/LigeroSmart/ligerosmart" \
    DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=C.UTF-8 \
    APP_DIR=/opt/otrs \
    APP_USER=otrs \
    APP_GROUP=www-data \
    DATABASE_CHECK=1 \
    MIGRATIONS_CHECK=1 \
    START_SCHEDULER=0 \
    START_WEBSERVER=0 \
    SMTPSERVER=mail \
    SMTPPORT=25 \
    EMAIL=otrs@localhost \
    EMAILPASSWORD=passw0rd \
    DEBUG_MODE=0 

ENV PATH=${APP_DIR}/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

SHELL ["/bin/bash", "-c"]

# Language
RUN apt-get update \
    && apt-get install -y locales \
    && rm -rf /var/lib/apt/lists/* \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "pt_BR.UTF-8 UTF-8" >> /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=${LANG} \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# user config
RUN useradd -d ${APP_DIR} -c 'OTRS user' -g ${APP_GROUP} -s /bin/bash ${APP_USER} \
    && usermod -a -G tty ${APP_GROUP} \
    && usermod -a -G tty ${APP_USER} 

# Include files
COPY --chown=${APP_USER}:${APP_GROUP} var /var
COPY etc /etc
COPY usr /usr
COPY root /root
COPY app-init.d/* /app-init.d/
COPY app-packages/* /app-packages/
COPY app-init.sh /app-init.sh
COPY app-run.sh /app-run.sh
COPY app-scheduler.sh /app-scheduler.sh

# Packages
RUN apt-get update \
    && apt-get install -y \
        bash-completion \
        bind9-host \
        cron \
        curl \
        dialog \
        gettext \
        git-core \
        gnupg \
        graphviz \
        jq \
        libaio1 \
        libarchive-zip-perl \
        libauthen-ntlm-perl \
        libauthen-sasl-perl \
        libconfig-inifiles-perl \
        libcrypt-eksblowfish-perl \
        libcrypt-ssleay-perl \
        libdate-pcalc-perl \
        libdatetime-perl \
        libdbd-mariadb-perl \
        libdbd-mysql-perl \
        libdbd-odbc-perl \
        libdbd-pg-perl \
        libdbi-perl \
        libencode-hanextra-perl \
        libgd-barcode-perl \
        libgraphviz-perl \
        libio-socket-ssl-perl \
        libjson-xs-perl \
        libmail-imapclient-perl \
        libnet-dns-perl \
        libnet-ldap-perl \
        libnuma1 \
        libreadline5 \
        libsnappy1v5 \
        libswitch-perl \
        libtemplate-perl \
        libterm-readline-perl-perl \
        libtext-csv-xs-perl \
        libtimedate-perl \
        libtinfo5 \
        libxml2-utils \
        libxml-libxml-perl \
        libxml-libxslt-perl \
        libxml-parser-perl \
        libyaml-libyaml-perl \
        perl \
        postgresql-client \
        rsync \
        sendmail \
        sudo \
        supervisor \
        tzdata \
        unzip \
        vim \
        xterm \
        zip \
    && apt autoremove -y mysql-common \
    && apt autoremove -y \
    && apt-get clean \
    && apt-get --purge remove sendmail-base sendmail-cf sendmail-doc -y \
    && rm -rf /var/lib/apt/lists/* 

# Extra perl modules
RUN apt update \
    && apt install -y \
            build-essential \
            libdb-dev \
            libexpat1-dev \
            libmariadb-dev \
            libssl-dev \
    && curl --silent -L https://cpanmin.us | perl - --sudo App::cpanminus \
    && cpanm --sudo --quiet --notest App::cpanoutdated \
    && cpan-outdated -p | cpanm --sudo --quiet --notest \
    && cpanm --sudo --quiet --notest Cache::Memcached::Fast \
    && cpanm --sudo --quiet --notest Cache::Redis \
    && cpanm --sudo --quiet --notest DateTime::TimeZone \
    && cpanm --sudo --quiet --notest HTTP::Server::Brick \
    && cpanm --sudo --quiet --notest JSON::Path \
    && cpanm --sudo --quiet --notest Plack \
    && cpanm --sudo --quiet --notest Plack::Middleware::Expires \
    && cpanm --sudo --quiet --notest Search::Elasticsearch@7.30 \
    && cpanm --sudo --quiet --notest HTTP::DAV \
    && cpanm --sudo --quiet --notest MIME::Words \
    && cpanm --sudo --quiet --notest Text::Markdown \
    && cpanm --sudo --quiet --notest Redis \
    && cpanm --sudo --quiet --notest Redis::Fast \
    && cpanm --sudo --quiet --notest Date::Calc \
    && cpanm --sudo --quiet --notest LWP::Authen::OAuth2 \
    && cpanm --sudo --quiet --notest Apache::DBI \
    && cpanm --sudo --quiet --notest DBD::MariaDB \
    && cpanm --sudo --quiet --notest GraphViz \
    && cpanm --sudo --quiet --notest Email::Valid \
    && apt remove --purge -y \
            build-essential \
            libdb-dev \
            libexpat1-dev \
            libmariadb-dev \
            libssl-dev \
    && apt autoremove -y \
    && apt install mariadb-client libmariadb3 libdbd-mysql-perl -y \
    && apt clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cpanm/

RUN mkdir ${APP_DIR} /app-backups 

WORKDIR ${APP_DIR}

# LigeroSmart code
RUN cd ${APP_DIR} \
    && git init \
    && git config core.fileMode false \
    && git config --global --add safe.directory /opt/otrs \
    && git config --global user.email ${APP_USER}@localhost \
    && git config --global core.mergeoptions "--strategy-option=theirs --allow-unrelated-histories --no-edit" \
    && git remote add origin ${CODE_REPOSITORY} \
    && git checkout -b main \
    && git pull origin ${RELEASE_TAG} \
    && mkdir -p ${APP_DIR}/var/article \ 
                ${APP_DIR}/var/spool \
                ${APP_DIR}/var/tmp \
    && chown otrs:www-data -R ${APP_DIR} \
    && chmod 775 -R ${APP_DIR} 

# post configuration
RUN mkdir -p /var/log/supervisor \
    && chmod +x /*.sh \
    && rm /etc/update-motd.d/* \
    && echo "PATH=\"$PATH\"" > /etc/environment

# aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && sudo ./aws/install \
    && rm -rf aws/ awscliv2.zip

COPY --from=gosendmail /bin/gosendmail /usr/sbin/sendmail

CMD /app-run.sh
