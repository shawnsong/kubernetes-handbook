# IP and port of etcd cluster
export ETCD1_IP="192.168.1.102"
export ETCD2_IP="192.168.1.103"
export ETCD3_IP="192.168.1.101"
export ETCD_PORT=2379

# IPs of master nodes
export MASTER1_IP="192.168.1.101"
export MASTER2_IP="192.168.1.102"
export MASTER3_IP="192.168.1.103"

# TLS Bootstrapping Token
# $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32;)
export BOOTSTRAP_TOKEN=khFZp2U5yWIgcjl0UsWU-cmeh05PQHXB

# Use unused netword ip range to define service ip and pod ip
# (Service CIDR)
export SERVICE_CIDR="10.254.0.0/16"

# Pod Cluster CIDR
export CLUSTER_CIDR="172.30.0.0/16"

# (NodePort Range)
export NODE_PORT_RANGE="30000-32766"

# etcd cluster addresses 
export ETCD_ENDPOINTS="https://$ETCD1_IP:$ETCD_PORT,https://$ETCD2_IP:$ETCD_PORT,https://$ETCD3_IP:$ETCD_PORT"

# flanneld etcd prefix
export FLANNEL_ETCD_PREFIX="/kubernetes/network"

# kubernetes service IP (normarlly the first IP in SERVICE_CIDR)
export CLUSTER_KUBERNETES_SVC_IP="10.254.0.1"

#  DNS IP for the cluster (assigned from SERVICE_CIDR)
export CLUSTER_DNS_SVC_IP="10.254.0.2"

#  DNS domain name 
export CLUSTER_DNS_DOMAIN="cluster.local"

# MASTER API Server 
export MASTER_URL="k8s-api.virtual.local"


