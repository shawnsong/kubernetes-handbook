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
ExecStartPre=-/usr/bin/mkdir /run/flannel
ExecStart=/usr/k8s/bin/flanneld \
  $FLANNEL_CERTS \
  $ETCD_ENDPOINTS \
  $ETCD_PREFIX
ExecStartPost=/usr/k8s/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
Restart=on-failure

[Install]
WantedBy=multi-user.target
RequiredBy=docker.service
```
> Note:
Flannel needs to start before docker. After flannel systemd starts, it executes `mk-docker-opts.sh` script and this script will write subnet data into `/run/flannel/docker` which will be used as environment file by docker `systemd`. It will also set docker start options to `DOCKER_NETWORK_OPTIONS` variable which will be also be used in docker `systemd`.


### Modify `systemd` Unit for Docker
Add the environment file generated by Flannel and pass it to Docker start command.
```shell
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target firewalld.service

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
EnvironmentFile=-/run/flannel/docker
ExecStart=/usr/bin/dockerd $DOCKER_NETWORK_OPTIONS
ExecReload=/bin/kill -s HUP $MAINPID
ExecStartPost=/usr/sbin/iptables -P FORWARD ACCEPT
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target
```
Also, please make sure docker is using `cgroupfs` as the cgroup driver. The kube-dns might not be able to run properly if `systemd` is used.
```shell
cat << EOF > /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=cgroupfs"]
}
EOF
```


### Create `systemd` Unit for Kubelet
Create working directory first
```shell
sudo mkdir -p /var/lib/kubelet
```

Create `/etc/systemd/system/kubelet.service` file
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
  $CLUSTER_DNS \
  $CLUSTER_DOMAIN \
  $KUBE_LOGTOSTDERR \
  $KUBE_LOG_LEVEL \
  $KUBELET_ARGS

Restart=on-failure
RestartSec=5
KillMode=process

[Install]
WantedBy=multi-user.target
```

### Create `systemd` Unit for Kube-Proxy

Create working directory first
```shell
sudo mkdir -p /var/lib/kube-proxy
```

Create `/etc/systemd/system/kube-proxy.service` file
```shell
[Unit]
Description=kube-proxy: The Kubernetes Proxy Server
Documentation=https://kubernetes.io/docs/concepts/overview/components/#kube-proxy https://kubernetes.io/docs/reference/generated/kube-proxy/
After=network.target

[Service]
WorkingDirectory=/var/lib/kube-proxy
EnvironmentFile=-/usr/k8s/bin/env/kube-proxy
ExecStart=/usr/k8s/bin/kube-proxy \
  $BIND_ADDRESS \
  $HOST_NAME_OVERRIDE \
  $CLUSTER_CIDR \
  $KUBECONFIG \
  $KUBE_LOGTOSTDERR \
  $KUBE_LOG_LEVEL

Restart=on-failure
RestartSec=5
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
```

## Verify the Cluster

Create `pod-nginx.yaml` with the following content:

```shell
apiVersion: v1
kind: Pod
metadata:
  name: nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx
    imagePullPolicy: IfNotPresent
```

Create `service-nginx.yaml` with the following content:

```shell
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  ports:
  - port: 8000 # the port that this service should serve on
    # the container on each pod to connect to, can be a name
    # (e.g. 'www') or a number (e.g. 80)
    targetPort: 80
    protocol: TCP
  # just like the selector in the deployment,
  # but this time it identifies the set of pods to load balance
  # traffic to.
  selector:
    app: nginx
```

Create the Pod and the Service:
```shell
kubectl create -f pod-nginx.yaml

kubectl create -f service-nginx.yaml
```

Check the Pod and the Service:
```shell
kubectl get pod
NAME      READY     STATUS    RESTARTS   AGE
nginx     1/1       Running   0          1h

kubectl get svc
NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
kubernetes      ClusterIP   10.254.0.1       <none>        443/TCP    39m
nginx-service   ClusterIP   10.254.189.113   <none>        8000/TCP   21h
```

Check if the Service and Pod are working correctly from worker node:
```shell
curl 10.254.189.113:8000
# should return nginx welcome page
```