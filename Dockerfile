# RStudio container used for Galaxy RStudio Integration

FROM quay.io/erasche/docker-rstudio-notebook:19.09-fixes<

RUN apt-get install --no-install-recommends -y libbz2-dev liblzma-dev

WORKDIR /import/

EXPOSE 80
