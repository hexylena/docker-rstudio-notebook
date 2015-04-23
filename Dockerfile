# RStudio container used for Galaxy RStudio Integration
#
# VERSION       0.1.0

FROM debian:squeeze

MAINTAINER Eric Rasche <rasche.eric@yandex.ru>

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US.UTF-8


# Ensure cran is available
RUN (echo "deb http://cran.mtu.edu/bin/linux/debian squeeze-cran3/" >> /etc/apt/sources.list && apt-key adv --keyserver keys.gnupg.net --recv-key 381BA480)
RUN (echo "deb-src http://http.debian.net/debian squeeze main" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)


# Install all requirements and clean up afterwards
RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y apt-transport-https \
    locales r-base r-base-dev dpkg wget psmisc libssl0.9.8 cron sudo \
    libcurl4-openssl-dev curl libxml2-dev nginx python python-pip net-tools lsb-release tcpdump unixodbc unixodbc-dev && \
    pip install bioblend argparse && \
    apt-get autoremove -y  && \
    apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN echo 'en_US.UTF-8 UTF-8' >> /etc/locale.gen
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales

# Install rstudio-server
RUN wget http://download2.rstudio.org/rstudio-server-0.98.1081-amd64.deb && dpkg -i rstudio-server-0.98.1081-amd64.deb && rm /rstudio-server-0.98.1081-amd64.deb

ADD rsession.conf /etc/rstudio/rsession.conf

COPY ./GalaxyConnector_0.0.1.tar.gz /tmp/GalaxyConnector.tar.gz
# Install packages
COPY ./packages.R /tmp/packages.R
RUN Rscript /tmp/packages.R &&  rm /tmp/packages.R


ADD ./startup.sh /startup.sh
RUN chmod +x /startup.sh

ADD ./monitor_traffic.sh /monitor_traffic.sh
RUN chmod +x /monitor_traffic.sh

# /import will be the universal mount-point for IPython
# The Galaxy instance can copy in data that needs to be present to the IPython webserver
RUN mkdir /import

COPY ./startup.sh /startup.sh
COPY ./proxy.conf /proxy.conf
COPY ./galaxy.py /usr/local/bin/galaxy.py
COPY ./Rprofile.site /usr/lib/R/etc/Rprofile.site

RUN chmod +x /startup.sh
RUN chmod +x /usr/local/bin/galaxy.py

VOLUME ["/import"]
WORKDIR /import/
# Start RStudio
CMD /startup.sh
