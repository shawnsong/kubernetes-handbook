# Affinity and anti-affinity

Affinity/anti-affinity is similar to nodeSelector but allows us to do more complex scheduling than the nodeSelector. nodeSelector can only apply the conditions on nodes while affinity/anti-affinity can also be applied to Pods. Also, unlike nodeSelector, affinity/anti-affinity rules does not have to be *hard* rules, which means a Pod can still be scheduled even if the rules are not met.

Kubernetes can do node affinity and pod affinity. Node affinity is similar to nodeSelector. Pod affinity allows to create rules that schedules Pods while taking other Pods into account. Those rules only relevant during scheduling. Once a Pod is scheduled, it needs to be killed and recreated to apply the rules again.

## Node Affinity

There are two types for node affinity:
1. requiredDuringSchedulingIgnoredDuringExecution
2. preferredDuringSchedulingIgnoredDuringExecution

The first is a hard requirement like nodeSelector (the cluster has to meet the rule to schedule a Pod) and the second is a soft requirement.

