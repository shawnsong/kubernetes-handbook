# Setup Kubernetes API Server

## Setup Environment Variables
```shell
export NODE_IP=192.168.1.101  # current node ip
source /usr/k8s/bin/env.sh
```

## Install kube-apiserver
```shell
curl -L -O https://dl.k8s.io/v1.9.2/kubernetes-server-linux-amd64.tar.gz
tar -xzvf kubernetes-server-linux-amd64.tar.gz
sudo cp -r server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler} /usr/k8s/bin/
```

## Create Kubernetes Certificates
```shell
cat > kubernetes-csr.json <<EOF
{
  "CN": "kubernetes",
  "hosts": [
    "127.0.0.1",
    "${NODE_IP}",
    "${MASTER_URL}",
    "${CLUSTER_KUBERNETES_SVC_IP}",
    "kubernetes",
    "kubernetes.default",
    "kubernetes.default.svc",
    "kubernetes.default.svc.cluster",
    "kubernetes.default.svc.cluster.local"
  ],
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
```
Generate certificates
```shell
cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes kubernetes-csr.json | cfssljson -bare kubernetes

sudo mkdir -p /etc/kubernetes/ssl/
sudo mv kubernetes*.pem /etc/kubernetes/ssl/
```
## Configure Token File
The token will be used by clients of api-server. For example, when a *kubelet* starts, it sends a TLS Bootstrap request. api-server will check if the token sent by kubelet is same with token.csv. If they match, api-server will generate certificates for that kubelet.
```shell
cat > token.csv <<EOF
${BOOTSTRAP_TOKEN},kubelet-bootstrap,10001,"system:kubelet-bootstrap"
EOF
```
*Note; BOOTSTRAP_TOKEN is defined in env.sh*

## Start kube-api-server
```shell
/usr/k8s/bin/kube-apiserver \
  --admission-control=NamespaceLifecycle,LimitRanger,ServiceAccount,DefaultStorageClass,ResourceQuota \
  --advertise-address=${NODE_IP} \
  --bind-address=0.0.0.0 \
  --insecure-bind-address=${NODE_IP} \
  --authorization-mode=Node,RBAC \
  --runtime-config=rbac.authorization.k8s.io/v1alpha1 \
  --kubelet-https=true \
  --enable-bootstrap-token-auth \
  --token-auth-file=/etc/kubernetes/token.csv \
  --service-cluster-ip-range=${SERVICE_CIDR} \
  --service-node-port-range=${NODE_PORT_RANGE} \
  --tls-cert-file=/etc/kubernetes/ssl/kubernetes.pem \
  --tls-private-key-file=/etc/kubernetes/ssl/kubernetes-key.pem \
  --client-ca-file=/etc/kubernetes/ssl/ca.pem \
  --service-account-key-file=/etc/kubernetes/ssl/ca-key.pem \
  --etcd-cafile=/etc/kubernetes/ssl/ca.pem \
  --etcd-certfile=/etc/kubernetes/ssl/kubernetes.pem \
  --etcd-keyfile=/etc/kubernetes/ssl/kubernetes-key.pem \
  --etcd-servers=${ETCD_ENDPOINTS} \
  --enable-swagger-ui=true \
  --allow-privileged=true \
  --apiserver-count=2 \
  --audit-log-maxage=30 \
  --audit-log-maxbackup=3 \
  --audit-log-maxsize=100 \
  --audit-log-path=/var/lib/audit.log \
  --audit-policy-file=/etc/kubernetes/audit-policy.yaml \
  --event-ttl=1h \
  --logtostderr=true \
  --v=2
```

Note:

 - *--insecure-bind-address is not available in 1.10*
 - kube-scheduler and kube-controller-manager are normally installed on the same machine with kube-apiserver so we can use insecure port for communication. However, I do not think this is possible since 1.10
 - kubelet, kube-proxy, kubectl are connected via secured port