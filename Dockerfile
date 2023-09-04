# RStudio container used for Galaxy RStudio Integration

FROM rocker/rstudio:4.3.1

ARG CONDA_VERSION=23.1.0
ARG SUFFIX=4
ARG MINIFORGE_VERSION=${CONDA_VERSION}-${SUFFIX}

ENV CONDA_PATH=/opt/miniconda \
    MINICONDA_BIN_DIR="/opt/miniconda/bin" \
    PATH="${PATH}:${MINICONDA_BIN_DIR}" \
    R_HOME='/opt/miniconda/lib/R'

RUN apt-get -qq update && \
    apt-get install --no-install-recommends -y wget psmisc procps sudo \
    libcurl4-openssl-dev curl libxml2-dev net-tools \
    lsb-release unixodbc unixodbc-dev odbcinst odbc-postgresql \
    texlive-latex-base texlive-extra-utils texlive-fonts-recommended \
    texlive-latex-recommended libapparmor1 libedit2 libcurl4-openssl-dev libssl-dev zlib1g-dev \
    libbz2-dev liblzma-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN cd /opt/ && \
    wget -q  "https://github.com/conda-forge/miniforge/releases/download/${MINIFORGE_VERSION}/Miniforge3-${MINIFORGE_VERSION}-Linux-x86_64.sh" \
        -O miniforge3.sh && \
    bash "./miniforge3.sh" -b -p ${CONDA_PATH} && \
    rm ./miniforge3.sh && \
    ${MINICONDA_BIN_DIR}/conda clean -tipy && \
    echo "conda activate base" >> "$CONDA_PATH/etc/profile.d/conda.sh" && \
    ln -s "$CONDA_PATH/etc/profile.d/conda.sh" /etc/profile.d/conda.sh && \
    echo ". $CONDA_PATH/etc/profile.d/conda.sh" >> ~/.bashrc && \
    chmod 777 ${CONDA_PATH} -R && \
    chmod 777 /tmp

COPY requirements.txt /tmp/requirements.txt

USER rstudio

#RUN cd /tmp/ && curl -fsSLO https://repo.anaconda.com/miniconda/Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
#    && bash Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
#    -b \
#    -p /opt/miniconda \
#    && rm -f Miniconda3-${miniconda3_version}-Linux-x86_64.sh \
#    && chown -R rstudio:rstudio /opt/miniconda \
#    && chmod -R go-w /opt/miniconda

RUN /opt/miniconda/bin/conda update -n base --yes conda \
    && /opt/miniconda/bin/conda config --append channels bioconda \
    && /opt/miniconda/bin/conda install --yes conda-libmamba-solver \
    && /opt/miniconda/bin/conda config --set solver libmamba \
    && /opt/miniconda/bin/conda install --file /tmp/requirements.txt -y \
    && /opt/miniconda/bin/conda clean -a

USER root

#COPY service-nginx-start /etc/services.d/nginx/run
#COPY service-nginx-stop  /etc/services.d/nginx/finish
#COPY proxy.conf          /etc/nginx/sites-enabled/default

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
