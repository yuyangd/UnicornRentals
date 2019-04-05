#! /bin/sh

set -eu

: ${NGINX_BACKEND:=${NGINX_BACKEND_HOST:-backend}:${NGINX_BACKEND_PORT:-80}}

# returns value of a given environment variable name
get_env_var() {
  eval "echo \"\${${1}-}\""
}

# returns the location for the n'th backend
get_nginx_location() {
  local number="$1"
  echo "$(get_env_var "NGINX_LOCATION_${number}")"
}

# returns the n'th backend
get_nginx_backend() {
  local idx="$1"
  local backend="$(get_env_var "NGINX_BACKEND_${idx}")"
  local host="$(get_env_var "NGINX_BACKEND_HOST_${idx}")"
  local port="$(get_env_var "NGINX_BACKEND_PORT_${idx}")"
  if [ -z "${backend}" ]; then
    if [ -n "${host}" -a -n "${port}" ]; then
      echo "${host}:${port}"
    else
      echo ""
    fi
  else
    echo "${backend}"
  fi
}

# generates nginx upstream config for given backend and upstream name
upstream_config() {
  local backend="$1" upstream="$2"
  cat <<EOF
upstream ${upstream} {
  server ${backend} fail_timeout=0;
}
EOF
}

# generates nginx location config for given backen and upstream name
location_config() {
  local location="$1" upstream="$2"
  cat <<EOF
  location ${location} {
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Request-Start "t=\${msec}";
    proxy_set_header Host \$http_host;
    proxy_redirect off;
    proxy_pass http://${upstream};
    proxy_buffering on;
    proxy_buffer_size ${NGINX_PROXY_BUFFERS_SIZE:-16k};
    proxy_buffers ${NGINX_PROXY_BUFFERS_COUNT:-8} ${NGINX_PROXY_BUFFERS_SIZE:-16k};
EOF

  if [ "${NGINX_LOG_FORMAT:-keyvalue}" = "json" ]; then
    cat <<EOF
    proxy_set_header X-Transaction-Id \$transaction_id;
    proxy_set_header X-Request-Id \$request_id;
EOF
  fi

  if [ -n "${NGINX_PROXY_READ_TIMEOUT-}" ]; then
    cat <<EOF
    proxy_read_timeout ${NGINX_PROXY_READ_TIMEOUT};
EOF
  fi

  if [ -n "${NGINX_MAX_SIZE-}" ]; then
    cat <<EOF
    proxy_cache container;
    proxy_cache_valid 200 302 3d;
    proxy_cache_valid 404 1m;
    proxy_cache_use_stale  error timeout invalid_header updating http_500 http_502 http_503 http_504;
    proxy_cache_background_update on;
    proxy_cache_lock on;
EOF
  fi
  cat <<EOF
  }
EOF
}

# returns upstream configs for all configured backends
generate_upstream_config() {
  for IDX in 0 1 2 3 4 5 6 7 8 9; do
    local backend="$(get_nginx_backend $IDX)"
    local location="$(get_nginx_location ${IDX})"
    if [ -n "${backend}" -a -n "${location}" ]; then
      echo "$(upstream_config "${backend}" "upstream_${IDX}")"
    fi
  done
  echo "$(upstream_config "${NGINX_BACKEND}" "upstream_default")"
}

# returns location configs for all configured backends
generate_location_config() {
  for IDX in 0 1 2 3 4 5 6 7 8 9; do
    local backend="$(get_nginx_backend $IDX)"
    local location="$(get_nginx_location ${IDX})"
    if [ -n "${backend}" -a -n "${location}" ]; then
      echo "$(location_config "${location}" "upstream_${IDX}")"
    fi
  done
  echo "$(location_config "/" "upstream_default")"
}

cat <<EOF
$(generate_upstream_config)
server {

  listen 80;

  client_header_timeout 15s;
  client_body_timeout 30s;
  client_max_body_size 4G;
  large_client_header_buffers ${NGINX_LARGE_CLIENT_HEADER_BUFFERS_COUNT:-4} ${NGINX_LARGE_CLIENT_HEADER_BUFFERS_SIZE:-16k};

  root /app/data;

$(generate_location_config)

}
EOF

if [ -n "${NGINX_MAX_SIZE-}" ]; then
cat <<EOF

proxy_cache_path /app/cache levels=1:2 keys_zone=container:10m max_size=${NGINX_MAX_SIZE} inactive=60m use_temp_path=off;
proxy_temp_path /app/cache/tmp;
proxy_cache_revalidate on;
EOF
fi