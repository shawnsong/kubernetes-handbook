# Setup Kubernetes Cluster from Scratch

## Component Versions and Cluster Environment
- Centos 7.3
- Kubernetes 1.9.2
- Docker 1.13.1
- etcd 3.2.9
- flannel v0.10.0

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

Disable firewalld on all servers:
```shell
sudo systemctl stop firewalld
sudo systemctl disable firewalld
```
We will turn the firewalld back on once we are more familiar with each components and have cluster running. Before reaching that point, it would be a lot easier to test all different components and setup a cluster without having a firewall interrupting the process.


## 1. Modify the env.sh to Align with Your Own Environment
[env.sh](env.sh) contains all the environment variables that we are going to use throught the whole Kubernetes cluster setup process. **Please be careful!**


## 2. Environment Variables
To do this, we need to run [setup-env.sh](setup-env.sh) script. This script will copy the `env.sh` to `/usr/k8s/bin` folder. If the folder does not exist, it will create it. It also adds etcd domain names to the `/etc/hosts` file. 


## 3. Cloudflare's CFSSL 
CFSSL is Cloudflare's PKI and TLS toolkit. We use CFSSL to generate all certificates. [install-cfssl.sh](install-cfssl.sh) will download and install CFSSL.

*Note: You don't need to install CFSSL on every machine. You can generate all certificates on one machines and `scp` them to the according servers.*


## 4. etcd Cluster

Etcd is a distributed key-value store written in Golang. It is used by Kubernetes to store ALLof the cluster's information and status. It is the most important component for a cluster. If your master nodes or worker nodes are failed, you might have a slow responding application, or the worst case, a failed application. However, if your data store is failed, you are pretty much done. 

Please refer [setup-static-etcd-cluster](etcd/setup-static-etcd-cluster.md) to setup the etcd cluster.


## 5. Kubectl

Kubectl is a Command Line Interface (CLI) that is used to run commands against Kubernetes cluster. All commands are sent by Kubectl to API Servers.

Please refer [setup-kubectl](kubectl/setup-kubectl.md) to setup Kubectl.


## 6. Flannel

Kubernetes runs a different network model than Docker does. The most fundamental difference is Kubernetes imposes a network model that NAT must NOT be used when container instances communicate with each other. Please find more details about the network model from the Kubernetes official website.

Please refer [setup-flannel](flannel/setup-flannel.md) to setup flannel.


## 7. Setup Master Node

Kubernetes master contains three components: Kube API Server, Kube Controller Manager and Kube Scheduler. Building a high available cluster is complicated and error proning. Hence, in this tutorial, a single node cluster will be built first. Once it is functional correctly, it can be easily extended to a cluster.

### 7.1 API Server

The functionality of Kubernetes API Server is as it is named. Users send commands to the cluster using Kubectl, which in turns sends all commands to the API Servers. When a command is sent to the API Server, it normally goes through 3 steps:
- Authentication
- Authorization
- Admission Control

Authentication and Authorization are standard access controls. Some Kubernetes features require Admission Controllers to be enabled to support the features. For example, `DenyEscalatingExec` can be turned on so users cannot run `exec` or `attach` against containers.

Please refer [kube-apiserver/setup-kube-apiserver.md](setup-kube-apiserver) to setup the API Server.

### 7.2 Controller Manger

Kubernetes Controller Manager is a Watch Dog that monitors the state of the cluster. It constantly checks the state of the entire clustser and makes it aligned with the desired state if they are different. For example, a pod requires 3 replicas running at any time. If any of the replica failed, the Controller Manager will identify this broken state and will try to start another replica to make it 3. The Controller Manager issues commands to the cluster via API Server.

Please refer [setup-kube-controller-manager](kube-controller-manager/setup-kube-controller-manager.md) to setup the Controller Manager.

### 7.3 Scheduler

Kubernetes Scheduler is the resource scheduler of the cluster. The scheduler determines where Pods/Containers should be running on.

Please refer [setup-kube-scheduler](kube-scheduler/setup-kube-scheduler.md) to setup the Scheduler

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


## 8. High-Available Cluster 

### 8.1 Setup Load Balancer
To make Kubernetes master nodes highly available, we need to setup a cluster for the master componenets. The Controller Manager and Scheduler components are using Master-Slave mode for high availability. The leader voting algorithm is implemented by Kubernetes itself, in combined with Raft consensus algorithm provided by etcd.

Hence, we only need to make the API Server highly available. To do that, we need to install a load-balancer, either HAProxy or Nginx, and make the load-balancer highly available. 

#### 8.1.1 Setup HAProxy
Please refer [setup-haproxy](load-balancer/setup-haproxy.md) to setup the HAProxy load balancer.

#### 8.1.2 Setup Nginx
Please refer [setup-nginx](load-balancer/setup-nginx.md) to setup a Nginx load balancer.

### 8.2 Setup Keepalived
Please refer [keep-alived](load-balancer/setup-keepalived.md) to setup Keepalived.

### 8.3 Setup High Available API Servers
Pelase refer the last section of [setup-kube-apiserver](kube-apiserver/setup-kube-apiserver.md) to setup high available API Servers.

### 8.4 Setup High Available Controller Manager and Scheduler
Unlike API Server, Controller Manager and Scheduler's high availability is relying on leader-election and etcd. So no configuration is required for high availability of these two components.

## 9. Deploy Worker Node
Kubernetes worker node requires these component:
- kubelet
- docker
- flannel
- kube-proxy


### 9.1 Setup Kubelet
Kubelet is an agent that required on each worker node. It works as a daemon that guarantees that containers are running inside pods. It is similar to `systemd` in Linux. Kubelet only 'monitors' containers started by Kubelet. User started containers are not monitored.

Please refer [setup-kubelet](kubelet/setup-kubelet.md) to setup Kubelet on worker nodes.

## 10. Wrap Up
### 10.1 Enable Firewall on Master Nodes
Now we have a production like highly available cluster running. We have one more step to go: enable the firewall. The OS used in this tutorial is CENTOS 7.4, so we use firewalld to config the firewall.

Please refer [enable-firewall](wrap-up/enable-firewall.md) to enable the firewall. 

### 10.2 Setup Daemon for Master Compnents
There are two ways to keep our master components (etcd, Controller, API Server, Scheduler) running all the time: first is to run all components in containers and let `Kubelet` to guarantee their running state. The second way is to make each component as a Linux Service and use Linux `systemd` to manage them. Using Kubelet will introduce 'Watching the watchers' issue (who is going to manage the state of Kubelet?), but it is more or less OS dependent. In This tutorial, we are going to make all components as services and let systemd to manage them.

Please refer [setup-services](wrap-up/setup-services.md) for the setup.