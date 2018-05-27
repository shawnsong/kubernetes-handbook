# Setup Kubernetes Cluster from Scratch

## Component Versions and Cluster Environment
- Centos 7.3
- Kubernetes 1.9.2
- Docker 1.13.1
- etcd 3.2.9
- flannel v0.10.0

## 1. Modify the env.sh to Align with Your Own Environment
[env.sh](env.sh) contains all the environment variables that we are going to use throught the whole kubernetes cluster setup process. **Please be careful!**

This is the details that is used in this guide:

Etcd cluster

| IP Address	| Hostname  |
|---------------|-----------|
| 192.168.1.102	| etcd1     |
| 192.168.1.103	| etcd2     |
| 192.168.1.101	| etcd3     |

Master nodes

| IP Address	| Role      |
|---------------|-----------|
| 192.168.1.101	| master1   |
| 192.168.1.102	| master2   |
| 192.168.1.103	| master3   |



## 2. Setup Environment Variables
To do this, we need to run [setup-env.sh](setup-env.sh) script. This script will copy the `env.sh` to `/usr/k8s/bin` folder. If the folder does not exist, it will create it. It also adds etcd domain names to the `/etc/hosts` file. 

## 3. Setup Cloudflare's CFSSL 
CFSSL is Cloudflare's PKI and TLS toolkit. We use CFSSL to generate all certificates. [install-cfssl.sh](install-cfssl.sh) will download and install CFSSL.

*Note: You don't need to install CFSSL on every machine. You can generate all certificates on one machines and `scp` them to the according servers.*

## 4. Setup etcd Cluster

Etcd is a distributed key-value store written in Golang. It is used by Kubernetes to store ALLof the cluster's information and status. It is the most important component for a cluster. If your master nodes or worker nodes are failed, you might have a slow responding application, or the worst case, a failed application. However, if your data store is failed, you are pretty much done. 

Please refer [setup-static-etcd-cluster](etcd/setup-static-etcd-cluster.md) to setup the etcd cluster.

## 5. Setup Kubectl

Kubectl is a Command Line Interface (CLI) that is used to run commands against Kubernetes cluster. All commands are sent by Kubectl to API Servers.

Please refer [setup-kubectl](kubectl/setup-kubectl.md) to setup Kubectl.

## 6. Setup Flannel

Kubernetes runs a different network model than Docker does. The most fundamental difference is Kubernetes imposes a network model that NAT must NOT be used when container instances communicate with each other. Please find more details about the network model from the Kubernetes official website.

Please refer [setup-flannel](flannel/setup-flannel.md) to setup flannel.

## 7. Setup Master Node

Kubernetes master contains three components: Kube API Server, Kube Controller Manager and Kube Scheduler. Building a high available cluster is complicated and error proning. Hence, in this tutorial, a single node cluster will be built first. Once it is functional correctly, it can be easily extended to a cluster.

### 7.1 Setup API Server

### 7.2 Setup Controller Manger

### 7.3 Setup Scheduler

### 7.4 Verify the Setup

To verify every component is installed and configured correctly, we use `kubectl` to check the status of the cluster:

```shell
kubectl get componentstatuses

# output should be similar to this
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-2               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
etcd-0               Healthy   {"health": "true"}

```

## 8. API Server High-Availability

### 8.1 Setup Load Balancer
To make Kubernetes master nodes highly available, we need to setup a cluster for the master componenets. The Controller Manager and Scheduler components are using Master-Slave mode for high-availability. The leader voting algorithm is implemented by Kubernetes itself, in combined with Raft consensus algorithm provided by etcd.

Hence, we only need to make the API Server highly available. To do that, we need to install a load-balancer, either HAProxy or Nginx, and make the load-balancer highly available. 

#### 8.1.1 Setup HAProxy
Please refer [load-balancer/setup-haproxy.md](setup-haproxy.md) to setup the HAProxy load balancer.

#### 8.1.2 Setup Nginx
Please refer [load-balancer/setup-nginx.md](setup-nginx.md) to setup a Nginx load balancer.

### 8.2 Setup Keepalived

## 9. Setup Kubelet
Kubelet is an agent that required on each worker node. It works as a daemon that guarantees that containers are running inside pods. It is similar to `systemd` in Linux. Kubelet only 'monitors' containers started by Kubelet. User started containers are not monitored.


Please refer[kubelet/setup-kubelet.md](setup-kubelet.md) to setup Kubelet on worker nodes.

