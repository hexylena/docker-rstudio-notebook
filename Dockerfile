FROM debian:squeeze
# Must use older version for libssl0.9.8
MAINTAINER Eric Rasche <rasche.eric@yandex.ru>

# Install all requirements and clean up afterwards
RUN DEBIAN_FRONTEND=noninteractive apt-get update

# Ensure cran is available
RUN (echo "deb http://cran.mtu.edu/bin/linux/debian squeeze-cran/" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)
RUN (echo "deb-src http://http.debian.net/debian squeeze main" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)

# Install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q r-base r-base-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q dpkg
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q wget
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q psmisc
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q libssl0.9.8
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q cron
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q sudo
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q libcurl4-openssl-dev curl
#RUN DEBIAN_FRONTEND=noninteractive apt-get build-dep -y -q libcurl4-openssl-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q libxml2-dev
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q nginx

RUN wget http://download2.rstudio.org/rstudio-server-0.98.987-amd64.deb
RUN dpkg -i rstudio-server-0.98.987-amd64.deb
RUN rm /rstudio-server-0.98.987-amd64.deb

RUN DEBIAN_FRONTEND=noninteractive apt-get autoremove -y
RUN DEBIAN_FRONTEND=noninteractive apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Install packages
ADD ./packages.R /tmp/packages.R
RUN Rscript /tmp/packages.R
RUN rm /tmp/packages.R

# Suicide
ADD ./monitor_traffic.sh /monitor_traffic.sh
RUN chmod +x /monitor_traffic.sh
RUN echo "* *     * * *   root    /monitor_traffic.sh" >> /etc/crontab

# /import will be the universal mount-point for IPython
# The Galaxy instance can copy in data that needs to be present to the IPython webserver
RUN mkdir /import
VOLUME ["/import/"]
WORKDIR /import/

ADD ./startup.sh /startup.sh
RUN chmod +x /startup.sh
ADD ./proxy.conf /proxy.conf

# RStudio will run on port 8787, export this port to the host system
EXPOSE 8787

# Start IPython Notebook
CMD /startup.sh
