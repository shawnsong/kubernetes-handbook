# Setup Kubernetes Cluster from Scratch

### 1. Modify the env.sh to align with your own environment
[env.sh](env.sh) contains all the environment variables that we are going to use throught the whole kubernetes cluster setup process. **Please be careful!**

This is the details that is used in this guide:

Etcd cluster

| IP Address	| hostname	|
|---------------|-----------|
| 192.168.1.102	| etcd1     |
| 192.168.1.103	| etcd2     |
| 192.168.1.101	| etcd3     |

### 2. Run setup-env.sh
[setup-env.sh](setup-env.sh) will copy the `env.sh` to `/usr/k8s/bin` folder. If the folder does not exist, it will create it. It also adds etcd domain names to the `/etc/hosts` file. Modify the ip addresses of etcd servers accordingly.

### 3. Run install-cfssl.sh
We use cfssl to generate all certificates. [install-cfssl.sh](install-cfssl.sh) will download and install cfssl.

### 4. Setup etcd cluster

