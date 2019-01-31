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
```
$ sudo firewall-cmd --zone=public --add-service=ceph-mon --permanent
```

```shell
$ kubectl exec -it pod-with-pvc /bin/sh
/ # ls
bin   dev   etc   home  mnt   proc  root  sys   tmp   usr   var
/ # ls /mnt/
SUCCESS     lost+found
```

We can see that the file `SUCCESS` is created under `/mnt/` directory, which means our persistent volume is working. Now, if we start another `busybox` and change the `command` to `sleep 3600` and still mounting the same PV, we can still see that `SUCCESS` is inside `/mnt/` directory. AWESOME!!