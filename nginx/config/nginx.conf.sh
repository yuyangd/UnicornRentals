#! /bin/sh

set -eu

cat <<EOF
user nginx;
worker_processes auto;
pid /run/nginx.pid;

events {
  worker_connections ${NGINX_WORKER_CONNECTIONS:-768};
  # multi_accept on;
}

http {

  ##
  # Basic Settings
  ##

  sendfile on;
  tcp_nopush on;
  tcp_nodelay on;
  types_hash_max_size 2048;
  underscores_in_headers ${NGINX_UNDERSCORES_IN_HEADERS:-off};
  server_tokens off;

  # server_names_hash_bucket_size 64;
  # server_name_in_redirect off;

  include /etc/nginx/mime.types;
  default_type application/octet-stream;

  ##
  # Logging Settings
  ##

  log_format keyvalue 'ip=\$remote_addr user=\$remote_user '
    'req="\$request" status=\$status bytes_sent=\$body_bytes_sent '
    'req_time=\$request_time ref="\$http_referer" '
    'ua="\$http_user_agent" forwarded="\$http_x_forwarded_for" '
    'cache_status=\$upstream_cache_status '
    'transaction_id="\$http_x_transaction_id" '
    'request_id="\$http_x_request_id" '
    'upstream_response_time=\$upstream_response_time';

  log_format json escape=json '{'
    '"timestamp":"\$time_iso8601_p1.\$millisec+\$time_iso8601_p2",'
    '"client_ip":"\$remote_addr",'
    '"user":"\$remote_user",'
    '"host":"\$host",'
    '"req_time":"\$request_time",'
    '"status":"\$status",'
    '"req_method":"\$request_method",'
    '"req_uri":"\$request_uri",'
    '"req_protocol":"\$server_protocol",'
    '"req_length":"\$request_length",'
    '"body_bytes_out":"\$body_bytes_sent",'
    '"bytes_out":"\$bytes_sent",'
    '"referer":"\$http_referer",'
    '"forwarded_for":"\$http_x_forwarded_for",'
    '"user_agent":"\$http_user_agent",'
    '"ssl_protocol":"\$ssl_protocol",'
    '"cache_status":"\$upstream_cache_status",'
    '"backend_response_time":"\$upstream_response_time",'
    '"backend_connect_time":"\$upstream_connect_time",'
    '"transaction_id":"\$transaction_id",'
    '"parent_request_id":"\$parent_request_id",'
    '"request_id":"\$request_id"'
    '}';

  ##
  # Tracing settings
  # Auto populate transaction and parent ids
  ##

  map \$http_x_transaction_id \$transaction_id {
    default \$http_x_transaction_id;
    "" \$request_id;
  }
  map \$http_x_request_id \$parent_request_id {
    default \$http_x_request_id;
  }
  map \$time_iso8601 \$time_iso8601_p1 {
    ~([^+]+) \$1;
  }
  map \$time_iso8601 \$time_iso8601_p2 {
    ~\\+([0-9:]+)\$ \$1;
  }
  map \$msec \$millisec {
    ~\\.([0-9]+)\$ \$1;
  }

  access_log /dev/stdout ${NGINX_LOG_FORMAT:-keyvalue};
  error_log /dev/stderr;

  ##
  # Gzip Settings
  ##

  gzip on;
  gzip_disable "MSIE [1-6]\.(?!.*SV1)";

  gzip_vary on;
  gzip_proxied any;
  gzip_comp_level 6;
  gzip_buffers 16 8k;
  gzip_http_version 1.1;
  gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript;

  ##
  # Virtual Host Configs
  ##

  include /etc/nginx/conf.d/*.conf;
  include /etc/nginx/sites-enabled/*;
}

daemon off;
EOF