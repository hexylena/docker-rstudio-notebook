#!/bin/bash

/etc/init.d/cron start
# Make sure time for /import/ to be mounted
sleep 3
CONF_FILE="/import/conf.yaml"
# Add the user

if [ ! -e "${CONF_FILE}" ];
then
    echo "Cannot have a missing conf file";
    exit 1;
fi
USERNAME=$(grep 'notebook_username' ${CONF_FILE} | sed 's/notebook_username: //g')
PASSWORD=$(grep 'notebook_password' ${CONF_FILE} | sed 's/notebook_password: //g')
DOCKER_PORT=$(grep 'docker_port' ${CONF_FILE} | sed 's/docker_port: //g')
# Req latest conf.yaml spec
CORS_ORIGIN=$(grep 'cors_origin' ${CONF_FILE} | sed 's/cors_origin: //g')

sed -i "s| '\*'; # IE_CORS_ORIGIN| '${CORS_ORIGIN}';|" /proxy.conf;
sed -i "s/IE_PORT/${DOCKER_PORT}/" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default
# Create user
useradd -p `openssl passwd -1 $PASSWORD` $USERNAME -d /import/
# Chown import as that user so they can write there
chown $USERNAME:$USERNAME /import/ -R
# Start the servers
service rstudio-server start
service nginx restart

echo 'library("yaml")
library("GalaxyConnector")' > /import/.Rprofile

chmod 777 /import/ -R
tail -f /var/log/nginx/*
