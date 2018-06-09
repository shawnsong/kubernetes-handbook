## Setup Linux Services

The recommended place for user generated systemd files is `/etc/systemd/system/` folder. All systemd files in this tutorial will be placed inside this folder.

### Create systemd for etcd


### Create systemd for API Server
```shell
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
Environment=NODE_IP=192.168.1.101
EnvironmentFile=/usr/k8s/bin/apiserver
ExecStart=/usr/k8s/bin/kube-apiserver \
  $KUBE_ADMISSION_CONTROL \
  $KUBE_API_ADVERTISE_ADDRESS \
  $KUBE_API_BIND_ADDRESS \
  $KUBE_API_INSECURE_ADDRESS \
  $KUBELET_AUTH
  $KUBE_SERVICE_ADDRESSES \
  $KUBE_SERVICE_NODE_PORT_RANGE \
  $KUBE_SSL_CERTS \
  $SERVICE_ACCOUNT_CONFIGS \
  $ETCD_SSL_CERTS \
  $KUBE_ETCD_SERVERS \
  $AUDIT_LOG_CONFIGS \
  $OTHER_CONFIGS
Restart=on-failure
RestartSec=5
Type=notify
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

