# RStudio container used for Galaxy RStudio Integration

FROM rocker/rstudio:4.1.0

ENV miniconda3_version="py39_4.9.2" \
    miniconda_bin_dir="/opt/miniconda/bin" \
    PATH="${PATH}:${miniconda_bin_dir}"

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y wget curl psmisc procps sudo \
    libcurl4-openssl-dev curl libxml2-dev nginx python python3-pip net-tools \
    lsb-release tcpdump unixodbc unixodbc-dev odbcinst odbc-postgresql \
    texlive-latex-base texlive-extra-utils texlive-fonts-recommended \
    texlive-latex-recommended libapparmor1 libedit2 libcurl4-openssl-dev libssl-dev zlib1g-dev \
    libbz2-dev liblzma-dev && \
    pip3 install bioblend argparse

# Install miniconda
RUN chmod 777 /opt/
USER rstudio
RUN cd /tmp/ && curl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
    && bash Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
    -b \
    -p /opt/miniconda \
    && rm -f Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
    && chown -R rstudio:rstudio /opt/miniconda \
    && chmod -R go-w /opt/miniconda

RUN  /opt/miniconda/bin/conda clean -tipsy \
    && /opt/miniconda/bin/conda clean -a \
    && /opt/miniconda/bin/conda init \
    && echo ". /opt/miniconda/etc/profile.d/conda.sh" >> ~/.bashrc \
    && echo "conda activate base" >> ~/.bashrc \
    && /opt/miniconda/bin/conda config --add channels bioconda \
    && /opt/miniconda/bin/conda config --add channels conda-forge \
    && /opt/miniconda/bin/conda install mamba -y


COPY requirements.txt /tmp/requirements.txt
RUN /opt/miniconda/bin/mamba install --file /tmp/requirements.txt -y

USER root

RUN ln -s /opt/miniconda/etc/profile.d/conda.sh /etc/profile.d/conda.sh \
    && mkdir -p /etc/services.d/nginx \
    && chmod 777 /tmp

COPY service-nginx-start /etc/services.d/nginx/run
#COPY service-nginx-stop  /etc/services.d/nginx/finish
COPY proxy.conf          /etc/nginx/sites-enabled/default

# ENV variables to replace conf file from Galaxy
ENV DEBUG=false \
    GALAXY_WEB_PORT=10000 \
    CORS_ORIGIN=none \
    DOCKER_PORT=none \
    API_KEY=none \
    HISTORY_ID=none \
    REMOTE_HOST=none \
    GALAXY_URL=none \
    RSTUDIO_FULL=1 \
    DISABLE_AUTH=true

WORKDIR /import/

ADD ./GalaxyConnector /tmp/GalaxyConnector
ADD ./packages/ /tmp/packages/
ADD ./logging.conf /etc/rstudio/

# The Galaxy instance can copy in data that needs to be present to the Rstudio webserver
RUN chmod 777 /import/

# the symlinks should be removed once the R scripts for gx_get/gx_put are smart enough to take the global put/get
RUN sed -i 's|/usr/local/bin/R|/opt/miniconda/bin/R|g' /etc/rstudio/disable_auth_rserver.conf \
    && ln -s /opt/miniconda/bin/get /usr/local/bin/get \
    && ln -s /opt/miniconda/bin/put /usr/local/bin/put

RUN /opt/miniconda/bin/Rscript /tmp/packages/gx.R

# Must happen later, otherwise GalaxyConnector is loaded by default, and fails,
# preventing ANY execution
#COPY ./Rprofile.site /opt/miniconda/lib/R/etc/Rprofile.site

COPY ./Rprofile.site /home/rstudio/.Rprofile

EXPOSE 80
