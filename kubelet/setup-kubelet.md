# Setup Kubelet

## Configure and Run Kubelet from Command Line
Kubelet is similar to a daemon process that monitors the containers state and keep them running. Kubelet interact with the cluster via API Server. To make our cluster secure, we want to enforce HTTPS connections between kubelet and API Server. If we have 1000 worker nodes, we need to create 1000 key/certificates. Manually managing those certificates is error prone and not scalable. Forturnately, we can use bootstrap token to authenticate our worker nodes and let the cluster to generate certificates for us automatically.

We have enabled bootstrap token authentication on our API Server (see [setup-apiserver](../kube-apiserver/setup-kube-apiserver.md)). When a Kubelet starts, it sends a bootstrap request. A new certificate will be generated, the system admin needs to approve the certificate to allow the worker node to join the cluster. To allow the worker to send bootstrap request to the API Server, we need to create a `system:node-bootstrapper` Cluster Role, and assign this role to `kubelet-bootstrap` user.

> Note: `kubelet-bootstrap` is the user specified in `token.csv`. 

- Create a cluster role in the cluster
```shell
# Environment variables
source /usr/k8s/bin/env.sh
export NODE_IP=192.168.1.101	# this is the ip of current node

kubectl create clusterrolebinding kubelet-bootstrap \ 
 --clusterrole=system:node-bootstrapper \
 --user=kubelet-bootstrap
```
Make sure the parameter assigned to `--user` is *same* as the user in `token.csv`.

The next step is to create a kubelet-bootstrap configuration file. This can be achieved by using `kubectl`.
- Configure the cluster parameters
```shell
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
```

- Configure authentication parameters
```shell
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
```

- Configure the context
```shell
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
```

- Use the default context
```shell
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
```
- Move `bootstrap.kubeconfig` to the correct folder
```shell
mv bootstrap.kubeconfig /etc/kubernetes/
```

The command to start Kubelet is as below. I highly recommand you read the notes first before starting Kubelet.
```shell
/usr/k8s/bin/kubelet \
  --fail-swap-on=false \
  --cgroup-driver=cgroupfs \
  --address=${NODE_IP} \
  --hostname-override=${NODE_IP} \
  --bootstrap-kubeconfig=/etc/kubernetes/bootstrap.kubeconfig \
  --kubeconfig=/etc/kubernetes/kubelet.kubeconfig \
  --cert-dir=/etc/kubernetes/ssl \
  --cluster-dns=${CLUSTER_DNS_SVC_IP} \
  --cluster-domain=${CLUSTER_DNS_DOMAIN} \
  --hairpin-mode promiscuous-bridge \
  --allow-privileged=true \
  --serialize-image-pulls=false \
  --logtostderr=true \
  --runtime-cgroups=/systemd/system.slice \
  --kubelet-cgroups=/systemd/system.slice \
  --v=2
```
> **Note**:  
  - Comment out `swap` in `/etc/fstab`. Also, make sure `--fail-swap-on` is set to `false`. This is required after Kubernetes 1.8
  - Make sure `--cgroup-driver` is set to the same driver that docker is using. This can be checked by running `docker info | grep cgroup`. It is recommended to use `cgroupfs` as kube-dns does not run properly in `systemd` mode after flannel is installed. Please refer [setup-services](../wrap-up/setup-services.md) to configure docker
  - Make sure `--hostname-override` is set to the same value on kube-proxy as well
  - Before Kubelet starts the first time, the file `--kubeconfig=/etc/kubernetes/kubelet.kubeconfig` does not exist. It is a location where Kubelet configuration file is stored. When Kubelet starts up the first time, it sends a bootstrap request to the cluster. The cluster will generate a certificate for this node. This certificate needs to be approved by system admin to allow this node to join the cluster. This file will only be generated after the certificates is approved. Next time when Kubelet starts again (machine reboot), it does not need to send a bootstrap request again, it will just reuse this configuration file.
  - `--hairpin-mode` is default to promiscuous-bridge. Hairpinning is where a machine on the LAN is able to access another machine on the LAN via the external IP address of the LAN/router (with port forwarding set up on the router to direct requests to the appropriate machine on the LAN).
  - `--serialize-image-pull` is set to false so that do not pull one images at a time. We recommend *not* changing the default value on nodes that run docker daemon with version < 1.9

## Setup Kubelet `systemd` Service
Please refer [setup-services](../wrap-up/setup-services.md) to create Kubelet service on each node.