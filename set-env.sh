#! /bin/bash

sudo mkdir -p /usr/k8s/bin
sudo cp env.sh /usr/k8s/bin

cat <<EOF | sudo tee -a /etc/hosts
192.168.1.102   etcd1
192.168.1.101   k8s-api.virtual.local k8s-api etcd3
192.168.1.103   etcd2
EOF