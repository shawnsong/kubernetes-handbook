ETCD1_IP="192.168.1.102"
ETCD2_IP="192.168.1.103"
ETCD3_IP="192.168.1.101"

ETCD_PORT=2379

# TLS Bootstrapping Token
BOOTSTRAP_TOKEN=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;)

# Use unused netword ip range to define service ip and pod ip
# (Service CIDR)
SERVICE_CIDR="10.254.0.0/16"

# Pod Cluster CIDR
CLUSTER_CIDR="172.30.0.0/16"

# (NodePort Range)
NODE_PORT_RANGE="30000-32766"

# etcd cluster addresses 
ETCD_ENDPOINTS="$ETCD1_IP:$ETCD_PORT,$ETCD2_IP:$ETCD_PORT,$ETCD3_IP:$ETCD_PORT"

# flanneld etcd prefix
FLANNEL_ETCD_PREFIX="/kubernetes/network"

# kubernetes service IP (normarlly the first IP in SERVICE_CIDR)
CLUSTER_KUBERNETES_SVC_IP="10.254.0.1"

#  DNS IP for the cluster (assigned from SERVICE_CIDR)
CLUSTER_DNS_SVC_IP="10.254.0.2"

#  DNS domain name 
CLUSTER_DNS_DOMAIN="cluster.local."

# MASTER API Server 
MASTER_URL="k8s-api.virtual.local"


