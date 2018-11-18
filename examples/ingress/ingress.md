# Ingress and Ingress Controller

Ingress provide a means to expose services that can be accessible from outside the cluster. Ingress defines all the rules to access the internal services. To use an Ingress, an Ingress Controller needs to be setup and running first.

The easiest way to expose services from within a cluster is to use `NodePort`. If there are very few services within the cluster, there is no problem of using this method. However, if the number of services grows, the downsides of this method starts to hurt. One inconvenience is that only ports between 30000-32767 are allowed for `NodePort`. Consequently, it requires more work to configure the load balancer once the nodes are shifted (the LB normally are configured directly pointing to the backend nodes). Having Ingress configured for the cluster can minimise the amount of work for external Load Balancers.

