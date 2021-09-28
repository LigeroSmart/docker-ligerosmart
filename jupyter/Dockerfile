FROM ligero/ligerosmart:6.1-base

ENV ARCHFLAGS='-arch x86_64'

RUN apt update \
    && apt install libzmq3-dev libcairo2-dev python3-pip build-essential -y \
    && python3 -m pip install jupyter bash_kernel \
    && cpanm --notest --build-args 'OTHERLDFLAGS=' ZMQ::LibZMQ3 \
    && cpanm --notest \
        Devel::IPerl \
        PDL \
        Moose \
        MooseX::AbstractFactory \
        MooseX::AbstractMethod \
        MooseX::Storage \
        Test::More \
    && apt remove --purge build-essential -y \
    && apt autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* 

COPY --chown=otrs:www-data jupyter-notebooks/ /jupyter-notebooks/
COPY etc/ /etc/

# Add Tini. Tini operates as a process subreaper for jupyter. This prevents
# kernel crashes.
ENV TINI_VERSION v0.6.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /usr/bin/tini
RUN chmod +x /usr/bin/tini
ENTRYPOINT ["/usr/bin/tini", "--"]

USER otrs

# load kernels
RUN python3 -m bash_kernel.install && iperl notebook --show-config

ENV JUPYTER_NOTEBOOK_DIR=/jupyter-notebooks/

CMD jupyter notebook --ip=0.0.0.0 --port 8888 --notebook-dir=$JUPYTER_NOTEBOOK_DIR