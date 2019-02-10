# StatefulSets

StatefulSets are introduced to manage stateful applications. Similar to Deployment, it manages pods based on one container spec and guarantees the number of Pods running in the cluster. The difference is, other than appending a random string at the end of each pod, the name of each pod is determinated. Once a pod is created, it is sticked with that name, which means the pod name will not be changed even if it is rescheduled. Therefore, the pods are not supposed to be interchangable (pods created by Deployment are interchangable).

## The Specials about StatefulSets

### Persistent Volume

In most of the cases, StatefulSets are required by stateful applications,  and stateful applications normally require persistent volumes attached to the pods. In order for a StatefulSets to be created, the storage must either be provisioned by a PersistentVolume Provisioner (check [this](../ceph/ceph.md) example) or pre-provisioned already. Also, another special feature about StatefulSets is tearingdown it will not delete the persisent volume attached to it. 

### Network Identity and Pod Names

StatefulSets applications are stateful, which means the pods running those applications are not interchangable and thus, we cannot rely on the Service automatic load balancing functionality. StatefulSets requires a Headless Service created to be responsible for the network identity of the Pods. 

As mentioned above, pod names are not created randomly. An ordinal number is appended at the end of the pod name in the format of `$(statefulset name)-$(ordinal)`. If a StatefulSets has 3 replicas and is called `web`, the three pod names are `web-0`, `web-1` and `web-2`. The final DNS name of a pod is: `$(pod name).$(headless service name).$(namespace).svc.cluster.local`. For example, the headless service name is `nginx`, the Pod DNS A record could be `web-0.nginx.default.svc.cluster.local`. 

## StatefulSets Use Case Explainations

After the above introduction, people may still be wondering why StatefulSets is created and when to use it. I will give a concrete example and try to illustrate its usage.

Let's say we have a distributed key/value cache which consists of 3 nodes (pod). Each pod would have its own data storage attached so it can retreive the data. From the application's point of view, we want to distribute the data evenly on the 3 nodes. A common algorithm is to hash the key and use the hash value mod 3. The result is the pod the application should access the data from, either get or put. 

Under this scenario, the pods are not interchangable and their network identity should always be stayed as unchanged (e.g. cache-1 cannot be changed to cache-0 or other numbers because the data is cached in memory and if the ID of the pod is changed, there would be cache misses all the times). StatefulSets suits perfectly for this kind of scenarios.

Another similar use case is we have a Cassandra cluster which consists of 1 master node and a few slave nodes. The slave nodes serve read requests and the master node serves read/write requests. All the write requests sent to slave nodes will be redirected to the master node. This requires the name/network ID of the master should alway stick with 1 value.