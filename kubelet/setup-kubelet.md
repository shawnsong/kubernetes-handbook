# Setup Kubelet

Kubelet is similar to a daemon process that monitors the containers state and keep them running. Kubelet interact with the cluster via API Server. To make our cluster secure, we want to enforce HTTPS connections between kubelet and API Server. If we have 1000 worker nodes, we need to create 1000 key/certificates. Manually managing those certificates is error prone and not scalable. Forturnately, we can use bootstrap token to authenticate our worker nodes and let the cluster to generate certificates for us automatically.

We have enabled bootstrap token authentication on our API Server (see [setup-apiserver](../kube-apiserver/setup-kube-apiserver.md)). When a Kubelet starts, it sends a bootstrap request. A new certificate will be generated, the system admin needs to approve the certificate to allow the worker node to join the cluster. To allow the worker to send bootstrap request to the API Server, we need to create a `system:node-bootstrapper` Cluster Role, and assign this role to `kubelet-bootstrap` user.

> Note: `kubelet-bootstrap` is the user specified in `token.csv`. 

Create a cluster role in the cluster
```shell
kubectl create clusterrolebinding kubelet-bootstrap --clusterrole=system:node-bootstrapper --user=kubelet-bootstrap
```

Make sure the `--user` is *same* the user in `token.csf`.

Create a RBAC 
```shell
kubectl create clusterrolebinding kubelet-nodes --clusterrole=system:node --group=system:nodes
```

Configure the cluster parameters
```shell
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=bootstrap.kubeconfig
```

Configure authentication parameters
```shell
kubectl config set-credentials kubelet-bootstrap \
  --token=${BOOTSTRAP_TOKEN} \
  --kubeconfig=bootstrap.kubeconfig
```

Configure the context
```shell
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kubelet-bootstrap \
  --kubeconfig=bootstrap.kubeconfig
```

Use the default context
```shell
kubectl config use-context default --kubeconfig=bootstrap.kubeconfig
```
