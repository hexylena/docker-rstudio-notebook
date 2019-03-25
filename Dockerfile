# RStudio container used for Galaxy RStudio Integration

FROM rocker/rstudio

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y wget psmisc procps sudo \
        libcurl4-openssl-dev curl libxml2-dev nginx python python-pip net-tools \
        lsb-release tcpdump unixodbc unixodbc-dev odbcinst odbc-postgresql \
        texlive-latex-base texlive-extra-utils texlive-fonts-recommended \
        texlive-latex-recommended libapparmor1 libedit2 libcurl4-openssl-dev libssl-dev zlib1g-dev && \
    pip install bioblend argparse

RUN mkdir -p /etc/services.d/nginx

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

VOLUME ["/import"]
WORKDIR /import/

ADD ./monitor_traffic.sh /monitor_traffic.sh
ADD ./GalaxyConnector /tmp/GalaxyConnector
ADD ./packages/ /tmp/packages/

# The Galaxy instance can copy in data that needs to be present to the Rstudio webserver
RUN Rscript /tmp/packages/updates.R && \
    Rscript /tmp/packages/devtools.R && \
    Rscript /tmp/packages/gx.R && \
    Rscript /tmp/packages/other.R && \
    Rscript /tmp/packages/bioconda.R && \
    pip install galaxy-ie-helpers

# Must happen later, otherwise GalaxyConnector is loaded by default, and fails,
# preventing ANY execution
COPY ./Rprofile.site /usr/local/lib/R/etc/Rprofile.site


EXPOSE 80
