# Node Selector

Kubernetes provides means to let users choose what nodes their Pods should be running on rather than relying on the Scheduler. For example, we want to schedule some Pods on the nodes which have SSD installed. There are a few ways to achieve this. Node Selector is the simplest way to start with.

## Add labels to Nodes

Run `kubectl get nodes` to get a list of nodes in the cluster and then run `kubectl label nodes <node-name> <label-key>=<label-value>` to label it:

```shell
$ kubectl get nodes


$ kubectl label nodes <node-name> <label-key>=<label-value>
```

Run `kubectl get nodes --show-labels` verify the node has been applied to the labels.

## Add a `nodeSelector` field to Pod configuration



## References

https://kubernetes.io/docs/concepts/configuration/assign-pod-node/