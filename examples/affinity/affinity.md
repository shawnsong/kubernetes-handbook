# Affinity and anti-affinity

Affinity/anti-affinity is similar to nodeSelector but allows us to do more complex scheduling than the nodeSelector. nodeSelector can only apply the conditions on nodes while affinity/anti-affinity can also be applied to Pods. Also, unlike nodeSelector, affinity/anti-affinity rules does not have to be *hard* rules, which means a Pod can still be scheduled even if the rules are not met.

Kubernetes can do node affinity and pod affinity. Node affinity is similar to nodeSelector. Pod affinity allows to create rules scheduling Pods taking other Pods into account