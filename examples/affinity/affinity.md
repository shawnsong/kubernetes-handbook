# Affinity and anti-affinity

Affinity/anti-affinity is similar to nodeSelector but allows us to do more complex scheduling than the nodeSelector. nodeSelector can only apply the conditions on nodes while affinity/anti-affinity can also be applied to Pods. Also, unlike nodeSelector, affinity/anti-affinity rules does not have to be *hard* rules, which means a Pod can still be scheduled even if the rules are not met.

Kubernetes can do node affinity and pod affinity. Node affinity is similar to nodeSelector. Pod affinity allows to create rules that schedules Pods while taking other Pods into account. Those rules only relevant during scheduling. Once a Pod is scheduled, it needs to be killed and recreated to apply the rules again.

## Node Affinity

There are 2 types for node affinity:
1. requiredDuringSchedulingIgnoredDuringExecution
2. preferredDuringSchedulingIgnoredDuringExecution

The first is a hard requirement like nodeSelector (the cluster has to meet the rule to schedule a Pod) and the second is a soft requirement.

## Node Affinity Examples and Explanations

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: with-node-affinity
spec:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: kubernetes.io/e2e-az-name
            operator: In
            values:
            - e2e-az1
            - e2e-az2
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 1
        preference:
          matchExpressions:
          - key: harddrive
            operator: In
            values:
            - ssd
  containers:
  - name: with-node-affinity
    image: k8s.gcr.io/pause:2.0
```

This node affinity rule says the pod can only be placed on a node with a label whose key is `kubernetes.io/e2e-az-name` and whose value is either `e2e-az1` or `e2e-az2` (this is a hard requirement). In addition, apart from this requirement, nodes with label of `harddrive=ssd` should be preferred but not mandatory (soft requirement).

In the above example, operator `In` is used to select nodes. All supported operators are: `In`, `NotIn`, `Exists`, `DoesNotExist`, `Gt` and `Lt`. `NotIn` and `DoesNotExist` are used for anti-affinity.

A few important rules:
- If `nodeSelector` and `nodeAffinity` are specified, a Pod can **only** be scheduled if **both** requirements are met. 
- if multiple `nodeSelectorTerms` are specified, **only one** needs to be met to schedule a Pod.
- If multiple `matchExpressions` associated with the `nodeSelectorTerms` are specified, **all** `matchExpressions` need to be satisfied to schedule a Pod.

## Node Affinity Demo

Please refer to [this](./deploy/node-affinity-required.yaml) file for Pod deployment. To schedule this Pod, we can see that it requires `hardware` in `high` *hard* requirement.

Before creating the Pods, let's check the node labels first.
```shell
$ kubectl get pods -o wide
NAME           STATUS   ROLES    AGE    VERSION   LABELS
192.168.1.51   Ready    <none>   116d   v1.13.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=192.168.1.51
192.168.1.52   Ready    <none>   97d    v1.13.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=192.168.1.52
192.168.1.61   Ready    <none>   32d    v1.13.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=192.168.1.61
192.168.1.62   Ready    <none>   32d    v1.13.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/hostname=192.168.1.62
```

There is no node labeled as `hardware=high` and therefore, no Pod should be scheduled. To verify this, run:
```shell
$ kubectl create -f node-affinity-required.yaml

$ kubectl get pods -o wide
...
node-affinity-77968676d9-dxpgd    0/1     Pending   0          <invalid>   <none>        <none>         <none>           <none>
node-affinity-77968676d9-ndzqh    0/1     Pending   0          <invalid>   <none>        <none>         <none>           <none>
node-affinity-77968676d9-wxdjn    0/1     Pending   0          <invalid>   <none>        <none>         <none>           <none>
...
```

It is as expexted that the Pods are pending in creation status.

Next, we add `hardware=high` label to `192.168.1.51` node
```shell
$ kubectl label nodes 192.168.1.51 hardware=high
node/192.168.1.51 labeled
$ kubectl get pods -o wide
...
node-affinity-77968676d9-dxpgd    0/1     ContainerCreating   0          <invalid>   <none>         192.168.1.51   <none>           <none>
node-affinity-77968676d9-ndzqh    1/1     Running             0          <invalid>   172.30.81.2    192.168.1.51   <none>           <none>
node-affinity-77968676d9-wxdjn    1/1     Running             0          <invalid>   172.30.81.10   192.168.1.51   <none>           <none>
...
```

All Pods are scheduled to `192.168.1.51`. Let's apply the same label to `192.168.1.52` as well: 
```shell
$ kubectl label nodes 192.168.1.51 hardware=high`
node/192.168.1.52 labeled

$ kubectl get po
```

After applying the label to `192.168.1.52` the Pods are still running on `192.168.1.51`, which is also as expected because affinity/anti-affinity is only relevant during Pod creation.

Now, delete the Pod and recreate them:
```shell
$ kubectl delete -f node-affinity-required.yaml
deployment.extensions "node-affinity" deleted

$ kubectl create -f node-affinity-required.yaml
deployment.extensions/node-affinity created

$ kubectl get pods -o wide
node-affinity-77968676d9-6nzxp    1/1     Running   0          21s    172.30.10.4   192.168.1.52   <none>           <none>
node-affinity-77968676d9-dxqpv    1/1     Running   0          21s    172.30.81.2   192.168.1.51   <none>           <none>
node-affinity-77968676d9-qnb4p    1/1     Running   0          21s    172.30.81.5   192.168.1.51   <none>           <none>
```

The Pods are scheduled on both `51` and `52`.

## Pod anti-affinity

Similar to node affinity, there are 2 types of Pod affinity as well:

1. requiredDuringSchedulingIgnoredDuringExecution
2. preferredDuringSchedulingIgnoredDuringExecution

A possible use case for Pod affinity is that a web application uses a cache such as redis. Hence, the application Pod is better co-located with the Redis Pod as much as possible because they need *communicate* with each other constantly. 

Pod anti-affinity should **always** be used with `preferredDuringSchedulingIgnoredDuringExecution` because it means spread the Pod in the whole cluster and `preferredDuringSchedulingIgnoredDuringExecution` would make no sense if the number of the Pods is greater than the number of nodes.

## Pod Affinity Examples and Explanations
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: service-1
  labels:
   	app: service-1
spec:
  affinity:
    podAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchExpressions:
          - key: app
            operator: In
            values:
            - redis-1
        topologyKey: kubernetes.io/hostname
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app
              operator: In
              values:
              - service-2
          topologyKey: kubernetes.io/hostname
  containers:
  - name: website
    image: nginx
    ports:
        - containerPort: 80
```

In this example, the Pod is `service-1` of a web application. It needs to scheduled on nodes that have a label whose key is `kubernetes.io/hostname` and value `V` which has Pod of label `app=redis-1` running on the node. For example, if `node1` has label `kubernetes.io/hostname` (it does not matter what the value is, as long as it has this label), also it has a Pod with label `app=redis-1` running on the node, then this Pod can be scheduled on `node1`.

Also, it says it's better to not schedule this Pod on nodes that have a label whose key is `kubernetes.io/hostname` and value is `V` that has Pod of lable `app=service-2` running on it.