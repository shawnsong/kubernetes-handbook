# Connect Ceph and Kubernetes

Get ceph client admin key
```shell
$ sudo ceph --cluster ceph auth get-key client.admin
```

create the secret for admin
```shell
$ kubectl create secret generic ceph-secret \
    --type="kubernetes.io/rbd" \
    --from-literal=key='AQBd6Upc798MDhAAcLAwKH00l978VWMgFbivuA==' \
    --namespace=kube-system
```


create a pool for Kubernetes
```shell
$ sudo ceph osd pool create kube 8
pool 'kube' created
sudo ceph --cluster ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'
[client.kube]
        key = AQC0QVBcxVPvExAAOoA4VyxEbL4jVSU3QlmMcA==
# if the output does not provide the key, use the following command to get the client.kube key
$ sudo ceph --cluster ceph auth get-key client.kube
AQC0QVBcxVPvExAAOoA4VyxEbL4jVSU3QlmMcA==
```

```shell
$ kubectl create secret generic ceph-secret-kube \
    --type="kubernetes.io/rbd" \
    --from-literal=key='AQC0QVBcxVPvExAAOoA4VyxEbL4jVSU3QlmMcA==' \
    --namespace=kube-system
```