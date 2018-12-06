# Daemon Sets

Daemon Sets ensure every node in the cluster run the same Pod. It is useful to make sure some Pods run on each single node. When a new node is joined to the cluster, the Pod will be started automatically. If a node is removed, the Pod will be garbage collected. That means the number of the Pod is always same as the number of nodes.

There are some typical use cases:
- Running monitoring daemon such as Prometheus, collectd, New Relic agent etc. on each node
- Running a log collection daemon on each node
- Running a distributed storage daemon such as Ceph 

