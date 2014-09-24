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
# Req latest conf.yaml spec
CORS_ORIGIN=$(grep 'cors_origin' ${CONF_FILE} | sed '/cors_origin: //g')
sed -i "s/'*'; # IE_MODIFY/'${CORS_ORIGIN}';/" /proxy.conf;
cp /proxy.conf /etc/nginx/sites-enabled/default


useradd -p `openssl passwd -1 $PASSWORD` $USERNAME -d /import/
chown $USERNAME:$USERNAME /import/ -R
# Start the server
service rstudio-server start
service nginx restart
sleep 1
curl localhost:8787/auth-public-key > /import/rserver_pub_key
chmod 777 /import/ -R
# TODO implement something useful -- is it worht the install rsyslog?
tail -f /var/log/*
