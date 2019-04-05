#! /bin/sh

/app/config/nginx.conf.sh > /etc/nginx/nginx.conf
/app/config/backend-proxy.conf.sh > /etc/nginx/conf.d/backend-proxy.conf

exec nginx