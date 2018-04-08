#! /bin/bash

source etcdenv.sh

cat > etcd-csr.json <<EOF
{
  "CN": "etcd",
  "hosts": [
    "127.0.0.1",
    "${NODE_IP}"
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

cfssl gencert -ca=/etc/kubernetes/ssl/ca.pem \
  -ca-key=/etc/kubernetes/ssl/ca-key.pem \
  -config=/etc/kubernetes/ssl/ca-config.json \
  -profile=kubernetes etcd-csr.json | cfssljson -bare etcd
echo "etcd tls is generated"
sudo mkdir -p /etc/etcd/ssl
sudo mv etcd*.pem /etc/etcd/ssl/
echo "etcd tls is copied to /etc/etcd/ssl/"

# set etcd working directory to /var/lib/etcd
sudo mkdir -p /var/lib/etcd
cat > etcd.service <<EOF
[Unit]
Description=Etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
WorkingDirectory=/var/lib/etcd/
ExecStart=/usr/k8s/bin/etcd \\
  --name=${CURRENT_NODE_NAME} \\
  --cert-file=/etc/etcd/ssl/etcd.pem \\
  --key-file=/etc/etcd/ssl/etcd-key.pem \\
  --peer-cert-file=/etc/etcd/ssl/etcd.pem \\
  --peer-key-file=/etc/etcd/ssl/etcd-key.pem \\
  --trusted-ca-file=/etc/kubernetes/ssl/ca.pem \\
  --peer-trusted-ca-file=/etc/kubernetes/ssl/ca.pem \\
  --initial-advertise-peer-urls=https://${CURRENT_NODE_IP}:2380 \\
  --listen-peer-urls=https://${CURRENT_NODE_IP}:2380 \\
  --listen-client-urls=https://${CURRENT_NODE_IP}:2379,http://127.0.0.1:2379 \\
  --advertise-client-urls=https://${CURRENT_NODE_IP}:2379 \\
  --initial-cluster-token=etcd-cluster-0 \\
  --initial-cluster=${ETCD_NODES} \\
  --initial-cluster-state=new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

sudo mv etcd.service /etc/systemd/system/
echo "etcd.service is created in /etc/systemd/system/"
echo "You can use systemctl to start etcd"
#sudo systemctl daemon-reload
#sudo systemctl enable etcd
#sudo systemctl start etcd
#sudo systemctl status etcd