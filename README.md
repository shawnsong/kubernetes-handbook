# Setup Kubernetes Cluster from Scratch

## 1. Modify the env.sh to Align with Your Own Environment
[env.sh](env.sh) contains all the environment variables that we are going to use throught the whole kubernetes cluster setup process. **Please be careful!**

This is the details that is used in this guide:

Etcd cluster

| IP Address	| hostname	|
|---------------|-----------|
| 192.168.1.102	| etcd1     |
| 192.168.1.103	| etcd2     |
| 192.168.1.101	| etcd3     |

## 2. Setup Environment Variables
To do this, we need to run [setup-env.sh](setup-env.sh) script. This script will copy the `env.sh` to `/usr/k8s/bin` folder. If the folder does not exist, it will create it. It also adds etcd domain names to the `/etc/hosts` file. 

## 3. Setup Cloudflare's CFSSL 
CFSSL is Cloudflare's PKI and TLS toolkit. We use CFSSL to generate all certificates. [install-cfssl.sh](install-cfssl.sh) will download and install CFSSL.

*Note: You don't need to install CFSSL on every machine. You can generate all certificates on one machines and `scp` them to the according servers.*

## 4. Setup etcd Cluster

## 5. Setup Kubectl

## 6. Setup Flannel

## 7. Setup Master Node

### 7.1 Setup API Server
### 7.2 Setup Controller Manger
### 7.3 Setup Scheduler