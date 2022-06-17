# HA with Kube-vip as static PODs

Use [Kube-VIP](https://plndr.io/kube-vip/) as a replacement for HAproxy and Keepalived.

It is deployed on the cluster as static PODs.

## Provision the environment

First we should create the environment by:

```bash
vagrant up
```

## Create the K8s cluster with the config file

Then the proper cluster configuration file [cluster-config-ha-kube-vip.yaml](../../../manifests/cluster-configs/cluster-config-ha-kube-vip.yaml) should be copied to the master node.

For initiating the cluster using the cluster configuration file, the following steps should be executed:

```bash
sudo kubeadm init \
    --config cluster-config-ha-kube-vip.yaml \
    --upload-certs
```

## Create the K8s cluster without config file

or without a cluster configuration:

```bash
sudo kubeadm init \
    --kubernetes-version 1.18.12 \
    --apiserver-advertise-address 192.168.100.11 \
    --pod-network-cidr 10.244.0.0/16 \
    --control-plane-endpoint kubeapi-vip:6443 \
    --upload-certs
```

## Apply the CNI

after the cluster is initialized and the config file is copied to `$HOME/.kube` we can apply a CNI (here Calico):

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## Join other master nodes

To join other master nodes to the cluster:

```bash
kubeadm join kubeapi-vip:6443 \
    --control-plane \
    --apiserver-advertise-address 192.168.200.12 \
    --apiserver-bind-port 8443 \
    --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash> \
    --certificate-key <certificate-key> \
    --ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests
```

## Join worker nodes

To join the worker nodes to the cluster:

```bash
sudo kubeadm join \
    kubeapi-vip:6443 \
    --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

### Generate token, hash, and certificate-key

To generate token and hash:

```bash
# Generate new token
sudo kubeadm token create

# List current tokens
sudo kubeadm token list

# Generate hash
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
            openssl dgst -sha256 -hex | sed 's/^.* //'

# Generate new certificate-key
sudo kubeadm alpha certs certificate-key
```
