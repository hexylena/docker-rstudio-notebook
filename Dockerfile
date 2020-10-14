# RStudio container used for Galaxy RStudio Integration

FROM rocker/rstudio:4.0.2

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y wget psmisc procps sudo \
        libcurl4-openssl-dev curl libxml2-dev nginx python python3-pip net-tools \
        lsb-release tcpdump unixodbc unixodbc-dev odbcinst odbc-postgresql \
        texlive-latex-base texlive-extra-utils texlive-fonts-recommended \
        texlive-latex-recommended libapparmor1 libedit2 libcurl4-openssl-dev libssl-dev zlib1g-dev \
        syslog-ng nano vim libbz2-dev liblzma-dev && \
    pip3 install bioblend argparse && \
    mkdir -p /etc/services.d/nginx && \
    chmod 777 /tmp

COPY service-nginx-start /etc/services.d/nginx/run
#COPY service-nginx-stop  /etc/services.d/nginx/finish
COPY proxy.conf          /etc/nginx/sites-enabled/default

RUN echo 'SYSLOGNG_OPTS="--caps cap_sys_admin,cap_chown,cap_dac_override,cap_net_bind_service,cap_fowner=eip"' >> /etc/syslog-ng/conf.d/rstudio.conf

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
RUN Rscript /tmp/packages/updates.R && \
    Rscript /tmp/packages/devtools.R && \
    Rscript /tmp/packages/gx.R && \
    Rscript /tmp/packages/other.R && \
    Rscript /tmp/packages/bioconda.R && \
    pip3 install git+https://github.com/bgruening/galaxy_ie_helpers.git@master && \
    chmod 777 /import/

# Must happen later, otherwise GalaxyConnector is loaded by default, and fails,
# preventing ANY execution
COPY ./Rprofile.site /usr/local/lib/R/etc/Rprofile.site

EXPOSE 80
