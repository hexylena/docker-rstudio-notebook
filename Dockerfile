# RStudio container used for Galaxy RStudio Integration

FROM rocker/rstudio

ENV PASSWORD=rstudio

#RUN apt-get -qq update && \
    #apt-get install --no-install-recommends -y apt-transport-https ca-certificates && \
    #echo "deb https://cran.rstudio.com/bin/linux/ubuntu trusty/" >> /etc/apt/sources.list && \
    #apt-key adv --keyserver keys.gnupg.net --recv-key 06F90DE5381BA480 && \
    #apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 51716619E084DAB9 && \

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y dpkg wget psmisc procps sudo \
        libcurl4-openssl-dev curl libxml2-dev nginx python python-pip net-tools \
        lsb-release tcpdump unixodbc unixodbc-dev odbcinst odbc-postgresql \
        texlive-latex-base texlive-extra-utils texlive-fonts-recommended \
        texlive-latex-recommended libapparmor1 libedit2 && \
    pip install bioblend argparse

	#libmyodbc

RUN mkdir -p /etc/services.d/nginx

COPY service-nginx-start /etc/services.d/nginx/start
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
    RSTUDIO_FULL=1

VOLUME ["/import"]
WORKDIR /import/

#RUN chmod +x /startup.sh && \
    #Rscript /tmp/packages-gx.R && \
    #pip install galaxy-ie-helpers && \
    #groupadd -r rstudio -g 1450 && \
    #useradd -u 1450 -r -g rstudio -d /import -c "RStudio User" \
        #-p $(openssl passwd -1 rstudio) rstudio && \
    #chown -R rstudio:rstudio /import

# Must happen later, otherwise GalaxyConnector is loaded by default, and fails,
# preventing ANY execution
COPY ./Rprofile.site /usr/lib/R/etc/Rprofile.site
