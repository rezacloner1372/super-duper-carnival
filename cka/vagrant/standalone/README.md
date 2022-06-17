# Standalone

An environment that has only **ONE** master node in the control plane but different number of worker nodes.

## Provision the environment

First we should create the environment by:

```bash
vagrant up
```

## Create the K8s cluster with the config file

Then the proper cluster configuration file [cluster-config-standalone.yaml](../../manifests/cluster-configs/cluster-config-standalone.yaml) should be copied to the master node.

For initiating the cluster using the cluster configuration file, the following steps should be executed:

```bash
sudo kubeadm init --config cluster-config-standalone.yaml
```

## Create the K8s cluster without config file

or without a cluster configuration:

```bash
sudo kubeadm init \
    --kubernetes-version 1.18.12 \
    --apiserver-advertise-address 192.168.100.11 \
    --pod-network-cidr 10.244.0.0/16
```

## Apply the CNI

after the cluster is initialized and the config file is copied to `$HOME/.kube` we can apply a CNI (here Calico):

```bash
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
```

## Join worker nodes

To join the worker nodes to the cluster:

```bash
sudo kubeadm join \
    192.168.100.11:6443 \
    --token <token> \
    --discovery-token-ca-cert-hash sha256:<hash>
```

### Generate token and hash

To generate token and hash:

```bash
# Generate new token
sudo kubeadm token create

# List current tokens
sudo kubeadm token list

# Generate has
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | \
            openssl dgst -sha256 -hex | sed 's/^.* //'
```
