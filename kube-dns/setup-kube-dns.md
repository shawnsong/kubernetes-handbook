# Setup Kube DNS

`kube-dns` is a Kubernetes plugin that helps Pods find other Services/Pods by domain names. It is just required to create a Pod and a Service to install this plugin. This is the [link](./kubedns.yaml) to the file. 

Run below command to install the plugin:
```shell
kubectl create -f kubedns.yaml
```

This will create a `Pod` and a `Service` in `kube-system` namespace. To verify, run the following commands:
```shell
kubectl get pods
NAME      READY     STATUS    RESTARTS   AGE
nginx     1/1       Running   0          1m

get svc --all-namespaces
NAMESPACE     NAME            TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)         AGE
default       kubernetes      ClusterIP   10.254.0.1       <none>        443/TCP         11d
kube-system   kube-dns        ClusterIP   10.254.0.2       <none>        53/UDP,53/TCP   1m
```
Note that `kube-dns` is installed inside `kube-system` namespace. The `Pod` and the `Service` look good, to verify they are working correctly, we need to deploy another service.