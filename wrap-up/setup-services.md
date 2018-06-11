## Setup Linux Services

The recommended place for user generated systemd files is `/etc/systemd/system/` folder. All systemd files in this tutorial will be placed inside this folder.

### Create `systemd` for etcd
There are many arguments need to be passed in when etcd is started. To keep the `systemd` file short and clean, it is better to store the environment configurations at a seperate place. There are two ways to setup the configurations. The first way is to use Linux environment variables. All variable names start with `ETCD_`, then the variable names with dashes replaced with underscores. For example, environment variable of `--name` is `ETCD_NAME`. The name of `--listen-client-urls` is `ETCD_LISTEN_CLIENT_URLS` etc. The second way to store the parameters is to use a seperate file. In this tutorial, we are going to use files to store start up parameters for all Kubernetes cluster components.

Create etcd environment file `etcd` in `/usr/k8s/bin/`. Please refer [etcd](environment/etcd) as an example.

Create the etcd systemd file `etcd.service` in `/etc/systemd/system/` with below content:

```shell
[Unit]
Description=etcd Server
After=network.target
After=network-online.target
Wants=network-online.target
Documentation=https://github.com/coreos

[Service]
Type=notify
EnvironmentFile=/usr/k8s/bin/etcd
WorkingDirectory=$WORKING_DIRECTORY
ExecStart=/usr/k8s/bin/etcd \
  $NODE_NAME \
  $INITIAL_ADVERTISE_PEER_URLS \
  $ETCD_LISTEN_PEER_URLS \
  $ETCD_LISTEN_CLIENT_URLS \
  $ETCD_ADVERTISE_CLIENT_URLS \
  $ETCD_INITIAL_CLUSTER_TOKEN \
  $ETCD_INITIAL_CLUSTER \
  $ETCD_INITIAL_CLUSTER_STATE \
  $ETCD_CERT_FILE \
  $ETCD_KEY_FILE \
  $ETCD_CLIENT_CERT_AUTH \
  $ETCD_TRUSTED_CA_FILE \
  $ETCD_PEER_CERT_FILE \
  $ETCD_PEER_KEY_FILE \
  $ETCD_PEER_CLIENT_CERT_AUTH \
  $ETCD_PEER_TRUSTED_CA_FILE \
  $ETCD_DATA_DIR
Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

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
  $KUBELET_AUTH \
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

