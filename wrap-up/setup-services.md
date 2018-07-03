## Setup Linux System Services

The recommended place for user generated systemd files is `/etc/systemd/system/` folder. All `systemd` unit files created in this tutorial will be placed inside this folder.

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
Similar to etcd, it is better to create a seperate file to store parameters for API Server bootstrap. There are several parameters that are used by all the components, so we create a file to store all shared parameters first, then create the API Server environment file.

Please refer [shared-config](../environment/shared-config) and [apiserver](../environment/apiserver) as an example.

```shell
[Unit]
Description=Kubernetes API Server
Documentation=https://github.com/GoogleCloudPlatform/kubernetes
After=network.target
After=etcd.service

[Service]
Environment=NODE_IP=192.168.1.101
EnvironmentFile=/usr/k8s/bin/env/shared-config
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
  $KUBE_LOG_LEVEL \
  $KUBE_LOGTOSTDERR \
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
When creating the `systemd` files, please make sure `Type=Notify` is **ONLY** applied to API Server and not to the Controller Manager and Scheduler. Otherwise, `systemd` will keep restarting Controller Manager and Scheduler due to a startup timeout (because only API Server sends a notify system call to indicate it is able to accept requests). Please refer `systemd` `man` page for more information.

### Create `systemd` Unit for Flannel

```shell
[Unit]
Description=Flanneld overlay address etcd agent
After=network.target
After=network-online.target
Wants=network-online.target
After=etcd.service
Before=docker.service

[Service]
EnvironmentFile=/usr/k8s/bin/env/flannel
ExecStart=/usr/k8s/bin/flanneld \
  $FLANNEL_CERTS \
  $ETCD_ENDPOINTS \
  $ETCD_PREFIX
ExecStartPost=/usr/k8s/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure
Type=notify

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
```

### Create `systemd` Unit for Kubelet
```shell
[Unit]
Description=kubelet: The Kubernetes Node Agent
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kubelet https://kubernetes.io/docs/reference/generated/kubelet/

[Service]
WorkingDirectory=/var/lib/kubelet
EnvironmentFile=-/usr/k8s/bin/env/kubelet
ExecStart=/usr/k8s/bin/kubelet \
  $KUBELET_ADDRESS \
  $KUBELET_HOSTNAME \
  $KUBELET_KUBECONFIG \
  $KUBE_LOGTOSTDERR \
  $KUBE_LOG_LEVEL \
  $KUBELET_ARGS

Restart=on-failure
KillMode=process

[Install]
WantedBy=multi-user.target
```