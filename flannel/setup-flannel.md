# Setup Flannel Network

## Install Flannel
```shell
source /usr/k8s/bin
export NODE_IP=192.168.1.101	# this is the ip of current node

curl -O -L https://github.com/coreos/flannel/releases/download/v0.9.0/flannel-v0.9.0-linux-amd64.tar.gz
tar -xzvf flannel-v0.9.0-linux-amd64.tar.gz -C flannel
sudo cp flannel/{flanneld,mk-docker-opts.sh} /usr/k8s/bin
```

## Create Flannel Certificates
```shell
cat > flanneld-csr.json <<EOF
{
  "CN": "flanneld",
  "hosts": [],
  "key": {
    "algo": "rsa",
    "size": 2048
  },
  "names": [
    {
      "C": "CN",
      "ST": "BeiJing",
      sudo mv flanneld*.pem /etc/flanneld/ssl
      sudo chown -R $USER:$USER
      "L": "BeiJing",
      "O": "k8s",
      "OU": "System"
    }
  ]
}
EOF

cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes flanneld-csr.json | cfssljson -bare flanneld

sudo mkdir -p /etc/flanneld/ssl
sudo mv flanneld*.pem /etc/flanneld/ssl
sudo chown -R $USER:$USER /etc/flanneld/ssl
```

## Put the Pod IP Ranges Configuration to etcd Cluster

*This step only needs to be done once. The reason is very obvious...*
```shell
etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/flanneld/ssl/flanneld.pem \
  --key-file=/etc/flanneld/ssl/flanneld-key.pem \
  set ${FLANNEL_ETCD_PREFIX}/config '{"Network":"'${CLUSTER_CIDR}'", "SubnetLen": 24, "Backend": {"Type": "vxlan"}}'
```
## Start Flannel
```shell
sudo /usr/k8s/bin/flanneld -etcd-cafile=/etc/kubernetes/ssl/ca.pem \
  -etcd-certfile=/etc/flanneld/ssl/flanneld.pem \
  -etcd-keyfile=/etc/flanneld/ssl/flanneld-key.pem \
  -etcd-endpoints=${ETCD_ENDPOINTS} \
  -etcd-prefix=${FLANNEL_ETCD_PREFIX}
```

## Check the Allocated IP Range
```shell
# do not use v3
export ETCDCTL_API=

etcdctl --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/flanneld/ssl/flanneld.pem \
  --key-file=/etc/flanneld/ssl/flanneld-key.pem \
  ls ${FLANNEL_ETCD_PREFIX}/subnets
# this returns /kubernetes/network/subnets/172.30.67.0-24
# so in next command, we get the info of 172.30.67.0-24
etcdctl \
  --endpoints=${ETCD_ENDPOINTS} \
  --ca-file=/etc/kubernetes/ssl/ca.pem \
  --cert-file=/etc/flanneld/ssl/flanneld.pem \
  --key-file=/etc/flanneld/ssl/flanneld-key.pem \
  get ${FLANNEL_ETCD_PREFIX}/subnets/172.30.67.0-24
```

## Repeat the previous steps on all nodes