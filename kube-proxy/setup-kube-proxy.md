# Setup Kube Proxy
Kube Proxy is required on each node to provide service discoverary functionality. It allows users to access 'Services' in Kubernetes, from both Pods and outside. 

There are two implementations for Kube Proxy: Namespace and Iptables. Iptables is the default option after v1.0.

## Create Certificates
```shell
# create certificate
cat > kube-proxy-csr.json <<EOF
{
  "CN": "system:kube-proxy",
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
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

# generate certificates
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy

# check files
ls kube-proxy
# kube-proxy.csr  kube-proxy-csr.json  kube-proxy-key.pem  kube-proxy.pem
sudo mv kube-proxy*.pem /etc/kubernetes/ssl/
```
## Create Kube Proxy `kubeconfig` File

Similar to the `kubelet` setup process, we will need to create a `kubeconfig` file to bootstrap kube-proxy on each node. 

```shell
# Configure the cluster parameters
kubectl config set-cluster kubernetes \
  --certificate-authority=/etc/kubernetes/ssl/ca.pem \
  --embed-certs=true \
  --server=${KUBE_APISERVER} \
  --kubeconfig=kube-proxy.kubeconfig

# Configure authentication parameters
kubectl config set-credentials kube-proxy \
  --client-certificate=/etc/kubernetes/ssl/kube-proxy.pem \
  --client-key=/etc/kubernetes/ssl/kube-proxy-key.pem \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

# Configure the context
kubectl config set-context default \
  --cluster=kubernetes \
  --user=kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

# Use the default context
kubectl config use-context default --kubeconfig=kube-proxy.kubeconfig

mv kube-proxy.kubeconfig /etc/kubernetes/
```

Start kube-proxy:
```shell
# set NODE_IP to the node's ip address
export NODE_IP=192.168.1.5
# setup environment variables
source /usr/k8s/bin/env.sh

# start kube-proxy
/usr/k8s/bin/kube-proxy \
  --bind-address=${NODE_IP} \
  --hostname-override=${NODE_IP} \
  --cluster-cidr=${SERVICE_CIDR} \
  --kubeconfig=/etc/kubernetes/kube-proxy.kubeconfig \
  --logtostderr=true \
  --v=2
```

After kube-proxy is start up, run `iptables --list` and you should have something similar to this:
```shell
Chain KUBE-FORWARD (1 references)
target     prot opt source               destination
ACCEPT     all  --  anywhere             anywhere             /* kubernetes forwarding rules */ mark match 0x4000/0x4000
ACCEPT     all  --  10.254.0.0/16        anywhere             /* kubernetes forwarding conntrack pod source rule */ ctstate RELATED,ESTABLISHED
ACCEPT     all  --  anywhere             10.254.0.0/16        /* kubernetes forwarding conntrack pod destination rule */ ctstate RELATED,ESTABLISHED
```

