# Setup Controller Manager

The kube-controller-manager execution file is copied to /usr/k8s/bin when we install the api-server so we can start the controller manager directly.

```shell
/usr/k8s/bin/kube-controller-manager \
  --address=127.0.0.1 \
  --master=http://${MASTER_URL}:8080 \
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

*Note: --address is deprecated in v1.10*