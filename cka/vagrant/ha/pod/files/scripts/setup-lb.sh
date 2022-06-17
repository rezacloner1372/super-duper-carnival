#!/usr/bin/env bash
set -o pipefail -o nounset -o xtrace -o errexit

# the port through which Kubernetes will talk to the API Server.
APISERVER_DEST_PORT="${APISERVER_DEST_PORT:-6443}"

# the port used by the API Server instances
APISERVER_SRC_PORT="${APISERVER_SRC_PORT:-6443}"

CONFIG_PATH="/etc/haproxy"

# populate backend servers
backend_servers=()
if [ "${MASTER_COUNT}" != "0" ]; then
    for i in $(seq 1 "$MASTER_COUNT"); do
        backend_servers+=("server ${MASTER_NAME}-$i ${MASTER_NAME}-$i:${APISERVER_SRC_PORT} check")
    done
fi

mkdir -p "$CONFIG_PATH"

# populate the haproxy config
cat >"$CONFIG_PATH/haproxy.cfg" <<EOF
#---------------------------------------------------------------------
# Global settings
#---------------------------------------------------------------------
global
    log /dev/log local0
    log /dev/log local1 notice
    daemon

#---------------------------------------------------------------------
# common defaults that all the 'listen' and 'backend' sections will
# use if not designated in their block
#---------------------------------------------------------------------
defaults
    mode                    http
    log                     global
    option                  httplog
    option                  dontlognull
    option http-server-close
    option forwardfor       except 127.0.0.0/8
    option                  redispatch
    retries                 1
    timeout http-request    10s
    timeout queue           20s
    timeout connect         5s
    timeout client          20s
    timeout server          20s
    timeout http-keep-alive 10s
    timeout check           10s

#---------------------------------------------------------------------
# apiserver frontend which proxys to the masters
#---------------------------------------------------------------------
frontend apiserver
    bind *:${APISERVER_DEST_PORT}
    mode tcp
    option tcplog
    default_backend apiserver

#---------------------------------------------------------------------
# round robin balancing for apiserver
#---------------------------------------------------------------------
backend apiserver
    option httpchk GET /healthz
    http-check expect status 200
    mode tcp
    option ssl-hello-chk
    balance     roundrobin
$(for backend_server in "${backend_servers[@]}"; do echo "        $backend_server"; done)
EOF