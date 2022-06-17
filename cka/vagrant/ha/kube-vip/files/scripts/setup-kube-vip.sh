#!/usr/bin/env bash
set -o pipefail -o nounset -o xtrace -o errexit

MANIFESTS_PATH="/etc/kubernetes/manifests"
APISERVER_DEST_PORT="${APISERVER_DEST_PORT:-8443}"
APISERVER_SRC_PORT="${APISERVER_SRC_PORT:-6443}"
KUBE_VIP_CONFIG_PATH="/etc/kube-vip"
APISERVER_VIP="${APISERVER_VIP}"
MASTER_NUMBER="${MASTER_NUMBER}"

mkdir -p "$MANIFESTS_PATH"
mkdir -p "$KUBE_VIP_CONFIG_PATH"

cat >"$KUBE_VIP_CONFIG_PATH/config.yaml" <<EOF
localPeer:
  id: ${HOSTNAME}
  address: ${HOSTNAME}
  port: 10000
remotePeers:
$(
  for peer_number in $(seq 1 "$MASTER_COUNT"); do
    if [ "$peer_number" != "$MASTER_NUMBER" ]; then
      peer="$MASTER_NAME-$peer_number"
echo "  - id: $peer"
echo "    address: $peer"
echo "    port: 10000"
    fi
  done
)
vip: ${APISERVER_VIP}
gratuitousARP: true
singleNode: false
$(
  if [ "$MASTER_NUMBER" == "1" ]; then
    echo "startAsLeader: true"
  else
    echo "startAsLeader: false"
  fi
)
interface: ${INTERFACE}
loadBalancers:
  - name: API Server Load Balancer
    type: tcp
    port: ${APISERVER_SRC_PORT}
    bindToVip: false
    backends:
$(
    for backend_number in $(seq 1 "$MASTER_COUNT"); do
      backend_address="$MASTER_NAME-$backend_number"
echo "      - port: $APISERVER_DEST_PORT"
echo "        address: $backend_address"
    done
)
EOF

cat >"$MANIFESTS_PATH/kube-vip.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: kube-vip
  namespace: kube-system
spec:
  containers:
  - command:
    - /kube-vip
    - start
    - -c
    - /vip.yaml
    image: 'plndr/kube-vip:0.1.1'
    name: kube-vip
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - SYS_TIME
    volumeMounts:
    - mountPath: /vip.yaml
      name: config
  hostNetwork: true
  volumes:
  - hostPath:
      path: /etc/kube-vip/config.yaml
    name: config
EOF