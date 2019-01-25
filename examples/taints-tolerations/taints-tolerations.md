# Taints and Tolerations

Node affinity is a configuration to schedule pods to a certain nodes. Taints, on the other hand, allow nodes to *reject* pods being scheduled on them unless they are *tolerated* to do so. Taints mark nodes and tolerations are applied to pods. For example, we can taint a node so no pod would be scheduled on this node and we can also apply tolerations to a pod so only that pod can be scheduled on that node.

## Concepts and Explanations

Similar to affinity, taints have both hard and soft requirements.
- **NoSchedule** is a hard requirement that a pod will not be scheduled unless there is a matching toleration
- **PreferNoSchedule** is a soft requirement.

If taints are applied to a node where there are already pods running on it, the pods will not be evicted unless **NoExecute** is applied.
- **NoExecute** will evict pods with no matching tolerations. When using `NoExecute`, we can specify how long a pod can run on a tainted node before it is evicted.


To add a taint to a node, use this command:
```shell
$ kubectl taint node node1 key=value:NoSchedule
```
This would prevent `node1` from being scheduled with any pod if there is no matching tolerations applied. However, a pod can be scheduled on `node` if there is a matching toleration defined:
```yaml
...
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
...
```

The below example shows a pod can keep running on a node for 10 minutes before it gets evicted. If `tolerationSeconds` is not specified, this pod will keep running.
```yaml
...
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoExecute"
  tolerationSeconds: 600
...
```

## Example Use Cases
- **Dedicated Nodes**: if we want to have a set of nodes dedicated for a group of users, we can taint those nodes and add tolerations to their pods. The pods with the tolerations will then be allowed to use the tainted (dedicated) nodes as well as any other nodes in the cluster. If you want to dedicate the nodes to them and ensure they only use the dedicated nodes, then you should additionally add a label similar to the taint to the same set of nodes (e.g. dedicated=groupName), and the admission controller should additionally add a node affinity to require that the pods can only schedule onto nodes labeled with dedicated=groupName
- **Nodes with specific hardware**:
