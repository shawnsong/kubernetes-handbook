# Setup Controller Manager

The kube-controller-manager execution file is copied to /usr/k8s/bin when we were installing the api-server so we can start the controller manager directly.

## Start the Controller Manager
We only have one API Server setup at this point, so we use MASTER1_IP for the `--master` option. This will be changed later.
```shell
# Setup Environment Variables
$ source /usr/k8s/bin/env.sh

# Start Controller Manager
$ /usr/k8s/bin/kube-controller-manager \
  --address=127.0.0.1 \
  --master=http://${MASTER1_IP}:8080 \
  --allocate-node-cidrs=true \
  --service-cluster-ip-range=${SERVICE_CIDR} \
  --cluster-cidr=${CLUSTER_CIDR} \
  --cluster-name=kubernetes \
  --cluster-signing-cert-file=/etc/kubernetes/ssl/ca.pem \
  --cluster-signing-key-file=/etc/kubernetes/ssl/ca-key.pem \
  --service-account-private-key-file=/etc/kubernetes/ssl/ca-key.pem \
  --root-ca-file=/etc/kubernetes/ssl/ca.pem \
  --leader-elect=true \
  --v=2
```

Explaination of options:
```shell
--address ip                                               DEPRECATED: the IP address on which to listen for the --port port. See --bind-address instead. (default 0.0.0.0)
--master string                                            The address of the Kubernetes API server (overrides any value in kubeconfig).
--allocate-node-cidrs                                      Should CIDRs for Pods be allocated and set on the cloud provider.
--service-cluster-ip-range string                          CIDR Range for Services in cluster. Requires --allocate-node-cidrs to be true
--cluster-cidr string                                      CIDR Range for Pods in cluster. Requires --allocate-node-cidrs to be true
--cluster-name string                                      The instance prefix for the cluster. (default "kubernetes")
--cluster-signing-cert-file string                         Filename containing a PEM-encoded X509 CA certificate used to issue cluster-scoped certificates (default "/etc/kubernetes/ca/ca.pem")
--cluster-signing-key-file string                          Filename containing a PEM-encoded RSA or ECDSA private key used to sign cluster-scoped certificates (default "/etc/kubernetes/ca/ca.key")
--service-account-private-key-file string                  Filename containing a PEM-encoded private RSA or ECDSA key used to sign service account tokens.
--v                                                        Log level
--bind-address ip                                          The IP address on which to listen for the --secure-port port. The associated interface(s) must be reachable by the rest of the cluster, and by CLI/web clients. If blank, all interfaces will be used (0.0.0.0 for all IPv4 interfaces and :: for all IPv6 interfaces). (default 0.0.0.0)
```

A full list of options can be gained from the Kubernetes official website.

## Point Controller Manager to the HAProxy
We can let `kube-controller-manager` points to the virtual IP of HAProxy directly: `192.168.1.201`, or we can use the hostname: `k8s-api.virtual.local`. 

```shell
# MASTER_URL is defined in env.sh
$ export KUBE_APISERVER="https://${MASTER_URL}"
# Use the above command but replace --master with below value
...
  --master=http://${KUBE_APISERVER} \
...
```
We removed the 8080 port number from the server URL because HAProxy will redirect HTTP request to 8080.