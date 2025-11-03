FROM ligero/ligerosmart:base

# Packages
RUN apt-get update \
    && apt-get install -y \
        bind9-host \
        htop \
        iputils-ping \
        net-tools \
        ldap-utils \
        mtr \
        ncdu \
        nmap \
        screen \
        ssh \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

RUN curl -L https://raw.githubusercontent.com/major/MySQLTuner-perl/master/mysqltuner.pl > /usr/local/bin/mysqltuner.pl \
    && chmod +x /usr/local/bin/mysqltuner.pl 

# include files
COPY etc /etc

RUN mkdir /var/run/sshd

# default env values for services
ENV START_SSHD=1 \
    DATABASE_CHECK=0 \
    MIGRATIONS_CHECK=0 \
    START_WEBSERVER=0 \
    START_SCHEDULER=0

