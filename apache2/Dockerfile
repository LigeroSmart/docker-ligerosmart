FROM ligero/ligerosmart:6.3-base

# Packages
RUN apt-get update \
    && apt-get install -y \
        apache2 \
        libapache2-mod-perl2 \
        lynx \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

# include files
COPY etc /etc
COPY usr /usr
COPY app-healthcheck.sh /

# post configuration
RUN ln -s /opt/otrs/scripts/apache2-httpd.include.conf /etc/apache2/conf-available/otrs.conf \
    && a2enmod headers perl include \
    && a2enconf otrs custom-config app-env \
    && cat /etc/apache2/app-envvars >> /etc/apache2/envvars \
    && cpanm --sudo --quiet --notest ModPerl::Util \
    && ln -sf /dev/stdout /var/log/apache2/access.log \
    && ln -sf /dev/stderr /var/log/apache2/error.log \
    && sed -i 's/access.log combined/access.log combined env=!dontlog/' /etc/apache2/sites-available/* \
    && echo ". /etc/environment" > /opt/otrs/.profile \
    && rm -rf /root/.cpanm/

EXPOSE 80

HEALTHCHECK --interval=20s --timeout=60s --retries=2 --start-period=10s CMD /app-healthcheck.sh

# default env values for services
ENV START_WEBSERVER=1 \
    START_SCHEDULER=1

