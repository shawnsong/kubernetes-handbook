# Ingress and Ingress Controller

Ingress provide a means to expose services that can be accessible from outside the cluster. Ingress defines all the rules to access the internal services. To use an Ingress, an Ingress Controller needs to be setup and running first.

The easiest way to expose services from within a cluster is to use `NodePort`. If there are very few services within the cluster, there is no problem of using this method. However, as the number of services grows, the downsides of this method starts to hurt. First of all, only ports between 30000-32767 are allowed for `NodePort`. Secondly, it requires more work to configure the load balancer once the nodes are shifted. 

## Create the Nginx Ingress Controller
Create the default backend first before creating the Ingress Controller:
```shell
$ kubectl create -f echoservice.yaml
```
Then create the Ingress Controller:
```shell
$ kubectl create -f nginx-ingress-controller.yaml
```

The first time when I ran this command, no pod was created. To check what might cause the issue, `kubectl describe` and `kubectl logs` are useful tools.

```shell
$ kubectl describe dadmonset nginx-ingress-controller

Events:
  Type     Reason        Age              From                  Message
  ----     ------        ----             ----                  -------
  Warning  FailedCreate  1d               daemonset-controller  Error creating: pods "nginx-ingress-controller-" is forbidden: error looking up service account default/nginx-ingress-serviceaccount: serviceaccount "nginx-ingress-serviceaccount" not found
  Warning  FailedCreate  1d               daemonset-controller  Error creating: pods "nginx-ingress-controller-wshhp" is forbidden: SecurityContext.RunAsUser is forbidden
  Warning  FailedCreate  1d               daemonset-controller  Error creating: pods "nginx-ingress-controller-4qgww" is forbidden: SecurityContext.RunAsUser is forbidden
  Warning  FailedCreate  1d               daemonset-controller  Error creating: pods "nginx-ingress-controller-zj8xd" is forbidden: SecurityContext.RunAsUser is forbidden
  Warning  FailedCreate  1d               daemonset-controller  Error creating: pods "nginx-ingress-controller-t54xm" is forbidden: SecurityContext.RunAsUser is forbidden
...
```

The first error message only appered once while the second one `SecurityContext.RunAsUser is forbidden` keeps repeating and causes the Pod failed to be created. After some research on Google and github.com, the root cause is that `ServiceContext` is denied by the API Server. Remove `SecurityContextDeny` from [apiconfig](../../environment/apiserver) and restart all API Server should resolve this issue.

```shell
$ kubectl describe ds nginx-ingress-controller

Name:           nginx-ingress-controller
Selector:       app=ingress-nginx
Node-Selector:  <none>
Labels:         app=ingress-nginx
Annotations:    <none>
Desired Number of Nodes Scheduled: 2
Current Number of Nodes Scheduled: 2
Number of Nodes Scheduled with Up-to-date Pods: 2
Number of Nodes Scheduled with Available Pods: 0
Number of Nodes Misscheduled: 0
Pods Status:  0 Running / 2 Waiting / 0 Succeeded / 0 Failed
Pod Template:
  Labels:           app=ingress-nginx
  Service Account:  nginx-ingress-serviceaccount
  Containers:
   nginx-ingress-controller:
    Image:  quay.io/kubernetes-ingress-controller/nginx-ingress-controller:0.17.1
    Ports:  80/TCP, 443/TCP
    Args:
      /nginx-ingress-controller
      --default-backend-service=$(POD_NAMESPACE)/echoheaders-default
      --configmap=$(POD_NAMESPACE)/nginx-configuration
      --tcp-services-configmap=$(POD_NAMESPACE)/tcp-services
      --udp-services-configmap=$(POD_NAMESPACE)/udp-services
      --publish-service=$(POD_NAMESPACE)/ingress-nginx
      --annotations-prefix=nginx.ingress.kubernetes.io
    Liveness:   http-get http://:10254/healthz delay=10s timeout=1s period=10s #success=1 #failure=3
    Readiness:  http-get http://:10254/healthz delay=0s timeout=1s period=10s #success=1 #failure=3
    Environment:
      POD_NAME:        (v1:metadata.name)
      POD_NAMESPACE:   (v1:metadata.namespace)
    Mounts:           <none>
  Volumes:            <none>
Events:
  Type     Reason            Age                From                  Message
  ----     ------            ----               ----                  -------
  Warning  FailedCreate      26s (x2 over 26s)  daemonset-controller  Error creating: pods "nginx-ingress-controller-" is forbidden: error looking up service account default/nginx-ingress-serviceaccount: serviceaccount "nginx-ingress-serviceaccount" not found
  Normal   SuccessfulCreate  25s                daemonset-controller  Created pod: nginx-ingress-controller-b9hf7
  Normal   SuccessfulCreate  25s                daemonset-controller  Created pod: nginx-ingress-controller-szpzd
```
Two Pods are created in this case because there are two worker nodes (minons) running in the cluster at the time of writing this handbook.


## Create Ingress Rules

The example used here is from [nginx-ingress-examples](https://github.com/nginxinc/kubernetes-ingress). There are two rules: `/tea` and `/coffee` are two services from the same host `cafe.example.com`. 

```shell
$ kubectl create -f cafe-ingress.yaml
```

Create the Pods and Services. This should create 3 `tea` Pods and 2 `coffee` Pods.
```shell
$ kubectl craete -f cafe.yaml
$ kubectl get pods
NAME                             READY     STATUS    RESTARTS   AGE
coffee-f5cd54465-rslxj           1/1       Running   0          39s
coffee-f5cd54465-zf4qr           1/1       Running   0          39s
echoheaders-jzs79                1/1       Running   0          1h
nginx-ingress-controller-b9hf7   1/1       Running   8          1h
nginx-ingress-controller-szpzd   1/1       Running   8          1h
tea-6bcb468bfc-8c2kt             1/1       Running   0          39s
tea-6bcb468bfc-bqs96             1/1       Running   0          39s
tea-6bcb468bfc-sth9v             1/1       Running   0          39s
```
