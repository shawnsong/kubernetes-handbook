#! /bin/bash

cd etcd

curl -L -O https://github.com/coreos/etcd/releases/download/v3.2.9/etcd-v3.2.9-linux-amd64.tar.gz
tar -xvf etcd-v3.2.9-linux-amd64.tar.gz
sudo mv etcd-v3.2.9-linux-amd64/etcd* /usr/k8s/bin/
