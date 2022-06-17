#!/usr/bin/env bash
set -o pipefail -o nounset -o xtrace -o errexit

LB_COUNT="${LB_COUNT:-0}"
LB_IP_START="${LB_IP_START:-0}"
LB_NAME="${LB_NAME:-LB}"

MASTER_IP_START="${MASTER_IP_START:-0}"
MASTER_COUNT="${MASTER_COUNT:-0}"
MASTER_NAME="${MASTER_NAME:-MASTER}"

WORKER_IP_START="${WORKER_IP_START:-0}"
WORKER_COUNT="${WORKER_COUNT:-0}"
WORKER_NAME="${WORKER_NAME:-WORKER}"

APISERVER_VIP="${APISERVER_VIP:-}"

TMP_HOSTS=/tmp/hosts

echo "Fix /etc/hosts entries"
sed -e '/^.*ubuntu-focal.*/d' -i /etc/hosts
ip_address="$(ip -4 addr show ${PRIVATE_INTERFACE_NAME} | grep "inet" | head -1 | awk '{print $2}' | cut -d/ -f1)"
sed -e "s/^.*${HOSTNAME}.*/${ip_address} ${HOSTNAME} ${HOSTNAME}.local/" -i /etc/hosts

echo "Update /etc/hosts about other hosts"

if [ "${MASTER_COUNT}" != "0" ]; then
    for i in $(seq 1 "$MASTER_COUNT"); do
        node_ip="${IP_NW}$(( MASTER_IP_START + i ))"
        node_hostname="${MASTER_NAME}-$i"
        if [ "$node_hostname" != "$HOSTNAME" ]; then
            echo "$node_ip  $node_hostname" >> "$TMP_HOSTS"
        fi
    done
fi

if [ "${WORKER_COUNT}" != "0" ]; then
    for i in $(seq 1 "$WORKER_COUNT"); do
        node_ip="${IP_NW}$(( WORKER_IP_START + i ))"
        node_hostname="${WORKER_NAME}-$i"
        if [ "$node_hostname" != "$HOSTNAME" ]; then
            echo "$node_ip  $node_hostname" >> "$TMP_HOSTS"
        fi
    done
fi

if [ "${LB_COUNT}" != "0" ]; then
    for i in $(seq 1 "$LB_COUNT"); do
        node_ip="${IP_NW}$(( LB_IP_START + i ))"
        node_hostname="${LB_NAME}-$i"
        if [ "$node_hostname" != "$HOSTNAME" ]; then
            echo "$node_ip  $node_hostname" >> "$TMP_HOSTS"
        fi
    done
fi

if [ ! -z "${APISERVER_VIP}" ]; then
    echo "${APISERVER_VIP}  kubeapi-vip" >> "$TMP_HOSTS"
fi

if [ -f "$TMP_HOSTS" ]; then
    cat "$TMP_HOSTS" >> /etc/hosts
fi