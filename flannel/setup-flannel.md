
# Setup Flannel Network

## Install Flannel
```shell
curl -O -L https://github.com/coreos/flannel/releases/download/v0.9.0/flannel-v0.9.0-linux-amd64.tar.gz
tar -xzvf flannel-v0.9.0-linux-amd64.tar.gz -C flannel
sudo cp flannel/{flanneld,mk-docker-opts.sh} /usr/k8s/bin
```

## Start Flannel
```shell
sudo /usr/k8s/bin/flanneld -etcd-cafile=/etc/kubernetes/ssl/ca.pem \
  -etcd-certfile=/etc/flanneld/ssl/flanneld.pem \
  -etcd-keyfile=/etc/flanneld/ssl/flanneld-key.pem \
  -etcd-endpoints=${ETCD_ENDPOINTS} \
  -etcd-prefix=${FLANNEL_ETCD_PREFIX}
```

## Check IP the range allocated to flanneld
``` shell
# do not use v3
export ETCDCTL_API=

etcdctl   --endpoints=${ETCD_ENDPOINTS}   --ca-file=/etc/kubernetes/ssl/ca.pem   --cert-file=/etc/flanneld/ssl/flanneld.pem   --key-file=/etc/flanneld/ssl/flanneld-key.pem   ls ${FLANNEL_ETCD_PREFIX}/subnets

etcdctl   --endpoints=${ETCD_ENDPOINTS}   --ca-file=/etc/kubernetes/ssl/ca.pem   --cert-file=/etc/flanneld/ssl/flanneld.pem   --key-file=/etc/flanneld/ssl/flanneld-key.pem   get ${FLANNEL_ETCD_PREFIX}/subnets/172.30.67.0-24
```

