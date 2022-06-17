# HA

There are different versions of an **HA** environment which has 3 master nodes in its control plane.

For more info look at [Kubernetes official website](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/)

For more info regarding the different type of load balancer look at [This Link](https://github.com/kubernetes/kubeadm/blob/master/docs/ha-considerations.md#options-for-software-load-balancing)

## Using dedicated haproxy machine

Look at [README](./lb/README.md)

## Using haproxy and keepalived as systemd services

Look at [README](./service/README.md)

## Using haproxy and keepalived as static PODs

Look at [README](./pod/README.md)

## Using Kube-vip

Look at [README](./kube-vip/README.md)
