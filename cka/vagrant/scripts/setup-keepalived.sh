#!/usr/bin/env bash
set -o pipefail -o nounset -o xtrace -o errexit

STATE="${STATE}"
INTERFACE="${INTERFACE}"
ROUTER_ID="${ROUTER_ID:-51}"
AUTH_PASS="${AUTH_PASS:-42}"
APISERVER_VIP="${APISERVER_VIP}"
APISERVER_DEST_PORT="${APISERVER_DEST_PORT:-6443}"
PRIORITY=0

case "$STATE" in
    "MASTER") PRIORITY=101 ;;
    "BACKUP") PRIORITY=100 ;;
esac

# install and configure keepalived
apt install --yes keepalived

cat >/etc/keepalived/check_apiserver.sh <<EOF
#!/usr/bin/env bash

errorExit() {
    echo "*** $*" 1>&2
    exit 1
}

curl --silent --max-time 2 --insecure https://localhost:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://localhost:${APISERVER_DEST_PORT}/"
if ip addr | grep -q ${APISERVER_VIP}; then
    curl --silent --max-time 2 --insecure https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/ -o /dev/null || errorExit "Error GET https://${APISERVER_VIP}:${APISERVER_DEST_PORT}/"
fi
EOF

chmod +x /etc/keepalived/check_apiserver.sh

cat >/etc/keepalived/keepalived.conf <<EOF
! Configuration File for keepalived
global_defs {
    router_id LVS_DEVEL
}
vrrp_script check_apiserver {
  script "/etc/keepalived/check_apiserver.sh"
  interval 3
  weight -2
  fall 10
  rise 2
}

vrrp_instance VI_1 {
    state ${STATE}
    interface ${INTERFACE}
    virtual_router_id ${ROUTER_ID}
    priority ${PRIORITY}
    authentication {
        auth_type PASS
        auth_pass ${AUTH_PASS}
    }
    virtual_ipaddress {
        ${APISERVER_VIP}
    }
    track_script {
        check_apiserver
    }
}
EOF

systemctl enable keepalived --now
systemctl restart keepalived
