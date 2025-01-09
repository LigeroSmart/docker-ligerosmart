FROM ligero/ligerosmart:6.3-base

# Packages
RUN apt update \
    && apt install -y \
        nginx \
        build-essential \
        libexpat1-dev \
        libssl-dev \
        libmysqlclient-dev \
        libpq-dev \
        unixodbc-dev \
        libperl-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*  

# Extra perl modules
RUN cpanm --sudo --quiet --notest \
        Starman \
        Devel::NYTProf \
        Perl::LanguageServer \
        Devel::StackTrace::WithLexicals \
        PadWalker \
        Plack::Middleware::Cache \
        Plack::Middleware::Expires \
    && rm -rf /root/.cpanm/

# include files
COPY etc /etc
COPY var /var
COPY app.psgi /
COPY app-init.d /app-init.d
COPY app-dev-run.sh /app-dev-run.sh
COPY app-healthcheck.sh /app-healthcheck.sh

# patches
RUN /var/patches/apply.sh

# post configuration
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log 
    
# module-tools
RUN git clone https://github.com/complemento/module-tools /opt/module-tools \
    && chown otrs -R /opt/module-tools

EXPOSE 80

HEALTHCHECK NONE

# default env values for services
ENV START_WEBSERVER=1 \
    START_SCHEDULER=1 \
    DEBUG_MODE=1 \
    PLACK_ENV=development \
    NYTPROF=start=no \
    CODE_BRANCH=rel-6_1


CMD /app-dev-run.sh
