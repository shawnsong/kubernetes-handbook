# Taints and Tolerations

Node affinity is a configuration to schedule Pods to a certain nodes. Taints, on the other hand, allow nodes to *reject* Pods being scheduled on them unless they are *tolerated* to do so. Taints mark nodes and tolerations are applied to Pods. For example, we can taint a node so no Pod would be scheduled on this node and we can also apply tolerations to a Pod so only that Pod can be scheduled on that node.

To add a taint to a node, use this command:
```shell
$ kubectl taint node node1 key=value:NoSchedule
```
This would prevent `node1` from being scheduled with any Pod if there is no matching tolerations applied. However, a pod can be scheduled on `node` if there is a matching toleration defined:
```shell
...
tolerations:
- key: "key"
  operator: "Equal"
  value: "value"
  effect: "NoSchedule"
...
```

