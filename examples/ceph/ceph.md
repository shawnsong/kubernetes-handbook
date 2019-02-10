# Integrate Ceph with Kubernetes

This examples shows how to integrate Ceph with Kubernetes to provide a storage solution for Kubernetes.

`rbd-provisioner` is a dynamic volume provisioner for Kubernetes. To connect an existing Ceph cluster to Kubernetes, it needs to be deployed in Kubernetes first.

For any client that interacts with Ceph, it needs to be authenticated. In this case, the `rbd-provisioner` will need to have credentials to communicate with Ceph cluster to provision PVCs.

> Note: the ceph cluster used in this example is from [this](https://github.com/shawnsong/ceph-handbook) setup.

## Create Ceph admin key for `rbd-provisioner`

On one of the Ceph monitor nodes, run this command to get ceph admin credentials first:
```shell
$ sudo ceph --cluster ceph auth get-key client.admin
AQBd6Upc798MDhAAcLAwKH00l978VWMgFbivuA==
```

Then create the secret for admin:
```shell
$ kubectl create secret generic ceph-secret \
    --type="kubernetes.io/rbd" \
    --from-literal=key='AQBd6Upc798MDhAAcLAwKH00l978VWMgFbivuA==' \
    --namespace=kube-system
```

## Create a Data Pool for Kubernetes

On one of the Ceph monitor nodes, create a Ceph user called `kube`:

```shell
$ sudo ceph osd pool create kube 8
pool 'kube' created
$ sudo ceph --cluster ceph auth get-or-create client.kube mon 'allow r' osd 'allow rwx pool=kube'
[client.kube]
        key = AQC0QVBcxVPvExAAOoA4VyxEbL4jVSU3QlmMcA==
# if the output does not provide the key, use the following command to get the client.kube key
$ sudo ceph --cluster ceph auth get-key client.kube
AQC0QVBcxVPvExAAOoA4VyxEbL4jVSU3QlmMcA==
```

Then create the secret for `kube` user in Kubernetes:
```shell
$ kubectl create secret generic ceph-secret-kube \
    --type="kubernetes.io/rbd" \
    --from-literal=key='AQC0QVBcxVPvExAAOoA4VyxEbL4jVSU3QlmMcA==' \
    --namespace=kube-system
```

The `ceph-secret` and `ceph-secret-kube` will be used by StorageClass.

Make sure `parameters.monitors` points to the correct Ceph monitor's IP Address and port. If the firewall is enabled on Ceph monitor, make sure that rules are added so that the firewall does not block the inbound connections. For example, create a file called `ceph-mon.xml` under `/etc/firewalld/services` with the following content:

```shell
<?xml version="1.0" encoding="utf-8"?>
<service>
  <short>ceph-mon</short>
  <description>Ceph Monitor</description>
  <port protocol="tcp" port="6800-7300"/>
</service>
```

And enable this rule:
```shell
$ sudo firewall-cmd --zone=public --add-service=ceph-mon --permanent
```

To test if Ceph monitors are reachable from pods, we can create a `busybox` box and ping the monitors from the pod.

## Create RBD Provisioner
```shell
$ cd deploy/rbd-provisioner
$ kubectl create -f .

clusterrolebinding.rbac.authorization.k8s.io/rbd-provisioner created
clusterrole.rbac.authorization.k8s.io/rbd-provisioner created
deployment.extensions/rbd-provisioner created
rolebinding.rbac.authorization.k8s.io/rbd-provisioner created
role.rbac.authorization.k8s.io/rbd-provisioner created
serviceaccount/rbd-provisioner created
```

And verify that the `rbd-provisioner` is running properly:
```shell
$ kubectl get po -n kube-system
NAME                               READY   STATUS    RESTARTS   AGE
...
rbd-provisioner-5647b5ff76-rrvvb   1/1     Running   0          60s
...
```

## Create StorageClass

```shell
$ kubectl create -f storage-class.yaml

$ kubectl get sc
$NAME       PROVISIONER    AGE
fast-rbd   ceph.com/rbd    60s
```

## Create PersistentVolumeClaim

```shell
$ kubectl create -f claim
```

## Mount the Storage to a Pod

In the [pod definition](./pod-with-pvc.yaml), it specifies the PersistenceVolumeClaim is `myclaim`, which was created just now in the previous step:
```shell
...
  volumes:
  - name: pvc
    persistentVolumeClaim:
      claimName: myclaim
```

Create the pod and login to the pod to check the volume is mounted
```shell
$ kubectl create -f pod-with-pvc.yaml

$ kubectl exec -it pod-with-pvc /bin/sh
/ # ls
bin   dev   etc   home  mnt   proc  root  sys   tmp   usr   var
/ # ls /mnt/
SUCCESS     lost+found
```

We can see that the file `SUCCESS` is created under `/mnt/` directory, which means our persistent volume is working. Now, if we start another `busybox` and change the `command` to `sleep 3600` and still mounting the same PV, we can still see that `SUCCESS` is inside `/mnt/` directory. AWESOME!!


## References
[RBD Volume Provisioner for Kubernetes 1.5+](https://github.com/kubernetes-incubator/external-storage/tree/master/ceph/rbd)
[Alen Komljen's blog](https://akomljen.com/using-existing-ceph-cluster-for-kubernetes-persistent-storage/)
[Ceph Installation Guide](http://docs.ceph.com/docs/master/start/)