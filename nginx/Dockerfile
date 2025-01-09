FROM ligero/ligerosmart:6.3-base

# Extra perl modules
RUN apt update \
    && apt install -y \
            build-essential \
    && cpanm --sudo --quiet --notest Starman \
    && cpanm --sudo --quiet --notest Devel::NYTProf \
    && apt remove --purge -y \
            build-essential \
            libexpat1-dev \
            libssl-dev \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /root/.cpanm/

# include config files
COPY etc /etc

# nginx repository key
RUN curl -L http://nginx.org/keys/nginx_signing.key > /tmp/nginx_signing.key && apt-key add /tmp/nginx_signing.key

# Packages
RUN apt-get update \
    && apt-get install -y \
        nginx=1.18.* \
    && apt-mark hold nginx=1.18.* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  

# include files
COPY var /var
COPY app.psgi /
COPY app-healthcheck.sh /app-healthcheck.sh

# patches
RUN /var/patches/apply.sh

# post configuration
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log \
    && echo ". /etc/environment" > /opt/otrs/.profile 
    
EXPOSE 80

HEALTHCHECK --interval=20s --timeout=60s --retries=2 --start-period=10s CMD /app-healthcheck.sh

# default env values for services
ENV START_WEBSERVER=1 \
    STARMAN_WORKERS=3 \
    START_SCHEDULER=1 \
    DEBUG_MODE=0 \
    PLACK_ENV=deployment \
    NYTPROF=start=no

