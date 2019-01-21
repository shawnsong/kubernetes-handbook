# Node Selector

Kubernetes provides means to let users choose what nodes their pods should be running on rather than relying on the Scheduler. For example, we want to schedule some pods on the nodes which have SSD installed. There are a few ways to achieve this. Node Selector is the simplest way to start with.

## Add labels to Nodes

Run `kubectl get nodes` to get a list of nodes in the cluster and then run `kubectl label nodes <node-name> <label-key>=<label-value>` to label it:

```shell
$ kubectl get nodes
NAME           STATUS   ROLES    AGE    VERSION
192.168.1.51   Ready    <none>   112d   v1.13.0
192.168.1.52   Ready    <none>   93d    v1.13.0
192.168.1.61   Ready    <none>   28d    v1.13.0
192.168.1.62   Ready    <none>   27d    v1.13.0

$ kubectl label nodes 192.168.1.51 hardware=high
$ kubectl label nodes 192.168.1.52 hardware=low
```

Run `kubectl get nodes --show-labels` verify the node has been applied to the labels.

## Add a `nodeSelector` field to pod configuration

```shell
...
spec:
  ...
  nodeSelector:
    hardware: high
...
```

Please refer to [this](../nginx-pod-high.yaml) and [this](../nginx-pod-low.yaml) for full example of pod definitions.

Create the pod:
```shell
$ kubectl create -f nginx-pod-high.yaml
pod/pod-on-high-end-node created
$ kubectl create -f nginx-pod-low.yaml
pod/pod-on-low-end-node created
```
Check where the pods are created:
```shell
$ kubectl get pods -o wide
NAME                              READY   STATUS    RESTARTS   AGE     IP            NODE           NOMINATED NODE   READINESS GATES
pod-on-high-end-node              1/1     Running   0          20m   172.30.81.9   192.168.1.51   <none>           <none>
pod-on-low-end-node               1/1     Running   0          89s   172.30.10.8   192.168.1.52   <none>           <none>
```

## References
https://kubernetes.io/docs/concepts/configuration/assign-pod-node/