#!/usr/bin/env bash
set -o pipefail -o nounset -o xtrace -o errexit

MANIFESTS_PATH="/etc/kubernetes/manifests"
APISERVER_DEST_PORT="${APISERVER_DEST_PORT:-8443}"
KEEPALIVED_CONFIG_PATH="/etc/keepalived"
HAPROXY_CONFIG_PATH="/etc/haproxy"

mkdir -p "$MANIFESTS_PATH"

cat >"$MANIFESTS_PATH/haproxy.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: haproxy
  namespace: kube-system
spec:
  containers:
  - image: haproxy:2.1.4
    name: haproxy
    livenessProbe:
      failureThreshold: 8
      httpGet:
        host: localhost
        path: /healthz
        port: ${APISERVER_DEST_PORT}
        scheme: HTTPS
    volumeMounts:
    - mountPath: /usr/local/etc/haproxy/haproxy.cfg
      name: haproxyconf
      readOnly: true
  hostNetwork: true
  volumes:
  - hostPath:
      path: $HAPROXY_CONFIG_PATH/haproxy.cfg
      type: FileOrCreate
    name: haproxyconf
EOF

cat >"$MANIFESTS_PATH/keepalived.yaml" <<EOF
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: null
  name: keepalived
  namespace: kube-system
spec:
  containers:
  - image: osixia/keepalived:1.3.5-1
    name: keepalived
    securityContext:
      capabilities:
        add:
        - NET_ADMIN
        - NET_BROADCAST
        - NET_RAW
    volumeMounts:
    - mountPath: /usr/local/etc/keepalived/keepalived.conf
      name: config
    - mountPath: /etc/keepalived/check_apiserver.sh
      name: check
  hostNetwork: true
  volumes:
  - hostPath:
      path: $KEEPALIVED_CONFIG_PATH/keepalived.conf
    name: config
  - hostPath:
      path: $KEEPALIVED_CONFIG_PATH/check_apiserver.sh
    name: check
EOF