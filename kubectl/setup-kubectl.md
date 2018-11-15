# Setup Kubectl

## Export Environment Variables
```shell
source /usr/k8s/bin/env.sh
export KUBE_APISERVER="https://${MASTER_URL}:6443"
```
## Download and Install Kubectl
```shell
curl -O -L https://dl.k8s.io/v1.9.2/kubernetes-client-linux-amd64.tar.gz 
tar -xzvf kubernetes-client-linux-amd64.tar.gz
sudo cp kubernetes/client/bin/kube* /usr/k8s/bin/
sudo chmod a+x /usr/k8s/bin/kube*
sudo chown $USER:USER /usr/k8s/bin/kube*
export PATH=/usr/k8s/bin:$PATH
```

## Create Admin Certificates

Because we could run kubectl on any machine (not necessarily on master nodes), hence, we need to encrypt the network between kubectl and kube-api-server. 


```shell
# Create admin-csr.json
cat > admin-csr.json <<EOF
{
  "CN": "admin",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      "L": "BeiJing",
      "O": "system:masters",
      "OU": "System"
    }
  ]
}
EOF

# Generate certificates
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes admin-csr.json | cfssljson -bare admin

sudo mv admin*.pem /etc/kubernetes/ssl/
```

## Use kubectl to Generate kubeconfig File
```shell
# Configure the certificates and the cluster
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER}

# Configure client side certificates
kubectl config set-credentials admin \
  --client-certificate=/etc/kubernetes/ssl/admin.pem \
  --embed-certs=true \
  --client-key=/etc/kubernetes/ssl/admin-key.pem \
  --token=${BOOTSTRAP_TOKEN}

# Create a new context
kubectl config set-context kubernetes \
  --cluster=kubernetes \
  --user=admin

# Set the context as default context
kubectl config use-context kubernetes
```
kubeconfig is saved in `~/.kube/config`


## Verify kubectl Configuration
Once the Kubectl is configured, we should be able to check the cluster's status:
```shell
kubectl get componentstatuses
```

> **Note:**  
  At the moment, `Kubectl` only points to a specific API server `https://MASTER1_IP:6443` to interact with the cluster. This is enough for now because we are going to build a single node cluster at the first step, then we will extend the master to a high-available cluster. Once we have a proper cluster setup, we can continue the following steps.

## Point kubectl to the HAProxy

We can let `kubectl` points to the virtual IP of HAProxy directly: `192.168.1.201`, or we can use the hostname: `k8s-api.virtual.local`. 

```shell
# MASTER_URL is defined in env.sh
export KUBE_APISERVER="https://${MASTER_URL}"
kubectl config set-cluster kubernetes --server=${KUBE_APISERVER}
```
We removed the 6443 port number from the server URL because HAProxy will redirect HTTPS request to 6443.

## Grant `cluster-admin` to Kubectl

As mentioned above, Kubectl interacts with the cluster via REST calls to API Server, which means it needs to be authenticated and authorised by the API Server. In the above example `BOOTSTRAP_TOKEN` is used for Kubectl. It is binded to `system:node-bootstrapper` which does not provide full access controls to the cluster. To give it full access, the ClusterRole `cluster-admin` can be used. 

The following steps need to be performed to achieve that:

1. Create a ServiceAccount for Kubectl. This will create a Secret associated with the ServiceAccount.
2. Create a ClusterRoleBinding. This is to bind the `cluster-admin` ClusterRole to the ServiceAccount.
3. Copy the secret to Kubectl config file

```shell
# create a ServiceAccount
$ kubectl create serviceaccount kubectl-clusteradmin
# create the ClusterROleBinding

$ kubectl create -f kubectl-admin-access.yaml

# get the Secret 
$ kubectl get secret
kubectl-clusteradmin-token-g7v59
# copy the token and paste into ~/.kube/config
$ kubectl describe secret kubectl-clusteradmin-token-g7v59
```
