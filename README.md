# kubernetes

## CKA

### Packer

See [README](./cka/packer/README.md)

### Vagrant

See [README](./cka/vagrant/README.md)

### Quick Start

#### Create a new Box or download it

```bash
cd packer
packer build .
```

#### Create Environment

```bash
cd ../vagrant/standalone
# open Vagrantfile and set variables:
## `BOX`:            Box name (`omidb11m/ubuntu-k8s`),
## `BOX_VERSION`     Box version (`0.1.1`),
## `SSH_WITH_PASS`:  true or false,
## `PUBLIC_KEY`:     your public key,
## `MASTER_COUNT`:   the number of the master nodes,
## `WORKER_COUNT`:   the number of the worker nodes
vagrant up
```

### Tips

#### To label worker nodes

```bash
kubectl label node kubeworker-1 kubernetes.io/role=node
```

#### To destroy all vagrant machines

```bash
vagrant destroy --force $(vagrant status --machine-readable | cut -d, -f2 | sort -u)
```

#### SSH to nodes

```bash
ssh anisa@kubemaster-1
```
