# Setup Kubernetes Cluster from Scratch

1. Run set-env.sh
This script will copy the env.sh to /usr/k8s/bin folder. It also adds etcd domain names to the /etc/hosts file. Modify the ip addresses of etcd servers accordingly.

2. Run install-cfssl.sh
We use cfssl to generate all certificates. This script will download and install cfssl.

3. Run generate-ca-cert.sh
This script will generate the root ca certificate and copy it to /etc/kubernetes/ssl

