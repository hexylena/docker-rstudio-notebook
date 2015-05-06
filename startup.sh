#!/bin/bash

/etc/init.d/cron start
# Make sure time for /import/ to be mounted
sleep 3

sed -i "s| '\*'; # IE_CORS_ORIGIN| '${CORS_ORIGIN}';|" /proxy.conf;
sed -i "s/IE_PORT/${DOCKER_PORT}/" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default
# Create user
useradd -p `openssl passwd -1 $NOTEBOOK_PASSWORD` galaxy -d /import/
# Chown import as that user so they can write there
chown galaxy:galaxy /import/ -R
# Start the servers
service rstudio-server start
service nginx restart

chmod 770 /import/ -R
tail -f /var/log/nginx/*
