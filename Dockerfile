FROM debian:squeeze
# Must use older version for libssl0.9.8
MAINTAINER Eric Rasche <rasche.eric@yandex.ru>

# Install all requirements and clean up afterwards
RUN DEBIAN_FRONTEND=noninteractive apt-get update --fix-missing

# Ensure cran is available
RUN (echo "deb http://cran.mtu.edu/bin/linux/debian squeeze-cran/" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)
RUN (echo "deb-src http://http.debian.net/debian squeeze main" >> /etc/apt/sources.list && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9)

RUN DEBIAN_FRONTEND=noninteractive apt-get update -q

# Install packages
RUN DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q \
    r-base r-base-dev dpkg wget psmisc libssl0.9.8 cron sudo libcurl4-openssl-dev \
    curl libxml2-dev nginx python python-pip && \
    pip install bioblend argparse && \
    DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y -q net-tools && DEBIAN_FRONTEND=noninteractive apt-get autoremove -y  && \
    DEBIAN_FRONTEND=noninteractive apt-get clean -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN wget http://download2.rstudio.org/rstudio-server-0.98.987-amd64.deb && dpkg -i rstudio-server-0.98.987-amd64.deb && rm /rstudio-server-0.98.987-amd64.deb

ADD rsession.conf /etc/rstudio/rsession.conf

COPY ./GalaxyConnector.tar.gz /tmp/GalaxyConnector.tar.gz
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
# Start IPython Notebook
CMD /startup.sh
