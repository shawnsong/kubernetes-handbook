## Setup Linux System Services

The recommended place for user generated systemd files is `/etc/systemd/system/` folder. All systemd files in this tutorial will be placed inside this folder.

### Create `systemd` Unit for etcd
There are many arguments need to be passed in during etcd bootstrap. To keep the `systemd` file short and clean, it is better to store the environment configurations at a seperate place. There are two ways to store the configurations. The first way is to use system environment variables. There is a easy-to-remember naming convention for etcd environment variables. The variable names start with `ETCD_`, followed by variable names with dashes replaced with underscores. For example, the variable name of `--name` is `ETCD_NAME`; the variable name of `--listen-client-urls` is `ETCD_LISTEN_CLIENT_URLS` and etc. The second way to store the parameters is to store them in a seperate file and pass the file to `systemd`. In this tutorial, we are going to use files to store bootstrap arguments for all Kubernetes cluster components.

Create etcd environment file `etcd` in `/usr/k8s/bin/env`. Please refer [etcd](../environment/etcd) as an example.

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
EnvironmentFile=/usr/k8s/bin/env/etcd
WorkingDirectory=/var/lib/etcd/
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

### Create `systemd` Unit for API Server
Similar to etcd, it is better to create a seperate file to store parameters for API Server bootstrap.

Please refer [apiserver](../environment/apiserver) as an example.

```shell
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
Environment=NODE_IP=192.168.1.101
EnvironmentFile=/usr/k8s/bin/env/apiserver
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

### Create `systemd` Unit for Controller Manager

```shell
[Unit]
Description=Kubernetes Controller Manager
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service
After=kube-api-server.service

[Service]
EnvironmentFile=/usr/k8s/bin/env/shared-config
EnvironmentFile=/usr/k8s/bin/env/controller-manager
ExecStart=/usr/k8s/bin/kube-controller-manager \
  $KUBE_MASTER \
  $BIND_ADDRESS \
  $KUBE_SERVICE_ADDRESSES \
  $KUBE_CLUSTER_CIDR \
  $KUBE_CLUSTER_CERTS \
  $KUBE_CONTROLLER_MANAGER_ARGS \
  $KUBE_LOG_LEVEL

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

### Create `systemd` Unit for Scheduler

```shell
[Unit]
Description=Kubernetes Scheduler
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service
After=kube-api-server.service

[Service]
EnvironmentFile=/usr/k8s/bin/env/shared-config
EnvironmentFile=/usr/k8s/bin/env/scheduler
ExecStart=/usr/k8s/bin/kube-scheduler \
  $BIND_ADDRESS \
  $KUBE_MASTER \
  $KUBE_SCHEDULER_ARGS \
  $KUBE_LOG_LEVEL

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

> Note:  
When creating the `systemd` files, please make sure `Type=Notify` is **ONLY** applied for API Server but not for the Controller Manager and Scheduler. Otherwise, `systemd` will keep restarting Controller Manager and Scheduler due to a startup timeout (because only API Server needs to send a notify system call to indicate it is able to accept requests).