FROM rocker/r-ver:3.5.0

ARG RSTUDIO_VERSION
## Comment the next line to use the latest RStudio Server version by default
#ENV RSTUDIO_VERSION=${RSTUDIO_VERSION:-1.1.447}
ENV PATH=/usr/lib/rstudio-server/bin:$PATH

## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
RUN apt-get update
RUN apt-get install -y --no-install-recommends file git libapparmor1 \
	libcurl4-openssl-dev libedit2 libssl-dev lsb-release psmisc python-setuptools \
	sudo wget multiarch-support procps

RUN wget -O libssl1.0.0.deb http://ftp.debian.org/debian/pool/main/o/openssl/libssl1.0.0_1.0.1t-1+deb8u7_amd64.deb 
RUN dpkg -i libssl1.0.0.deb 
RUN rm libssl1.0.0.deb 

ENV RSTUDIO_VERSION 1.1.453

RUN wget http://download2.rstudio.org/rstudio-server-${RSTUDIO_VERSION}-amd64.deb && \
    dpkg -i rstudio-server-${RSTUDIO_VERSION}-amd64.deb && \
    rm /rstudio-server-${RSTUDIO_VERSION}-amd64.deb

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8

RUN apt-get install --no-install-recommends -y locales
RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
RUN locale-gen en_US.UTF-8
RUN dpkg-reconfigure locales
RUN apt-get update && apt-get -y upgrade
RUN apt-get install --no-install-recommends -y \
        wget psmisc libssl1.0.0 procps sudo \
        libcurl4-openssl-dev curl libxml2-dev nginx python python-pip net-tools \
        lsb-release tcpdump unixodbc unixodbc-dev odbcinst odbc-postgresql \
        texlive-latex-base texlive-extra-utils texlive-fonts-recommended \
        texlive-latex-recommended libapparmor1 libedit2



RUN pip install -U setuptools pip
RUN pip install bioblend argparse
RUN apt-get autoremove -y
RUN apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ADD rsession.conf /etc/rstudio/rsession.conf

# Install packages
COPY ./packages.R /tmp/packages.R
RUN Rscript /tmp/packages.R

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

ADD ./startup.sh /startup.sh
ADD ./monitor_traffic.sh /monitor_traffic.sh
ADD ./proxy.conf /proxy.conf
ADD ./GalaxyConnector /tmp/GalaxyConnector
ADD ./packages-gx.R /tmp/packages-gx.R
ADD ./rserver.conf /etc/rstudio/rserver.conf

# /import will be the universal mount-point for IPython
RUN apt-get update && apt-get install -y r-base-dev
# The Galaxy instance can copy in data that needs to be present to the Rstudio webserver
RUN chmod +x /startup.sh && \
    Rscript /tmp/packages-gx.R && \
    pip install galaxy-ie-helpers && \
    groupadd -r rstudio -g 1450 && \
    mkdir /import && \
    useradd -u 1450 -r -g rstudio -d /import -c "RStudio User" \
        -p $(openssl passwd -1 rstudio) rstudio && \
    chown -R rstudio:rstudio /import

# Must happen later, otherwise GalaxyConnector is loaded by default, and fails,
# preventing ANY execution
COPY ./Rprofile.site /usr/lib/R/etc/Rprofile.site

# Start RStudio
CMD /startup.sh
EXPOSE 80
