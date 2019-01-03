# Horizontal Pod Autoscaler

Horizontal Pod Autoscaler automatically scales the number of pods in a replication controller, deployment or replica set based on observed CPU utilization or some other application-provided metrics. 

Prerequsites: 

- Metrics Server

This example is from Kubernetes Official Doc [HPA-Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/) with some modifications.

## Run & expose php-apache server

To demonstrate Horizontal Pod Autoscaler, a custom docker image based on php-apache will be used. This image contains a custom `index.php` page which performs some CPU intensive computations.

Dockerfile:
```shell
FROM php:5-apache
ADD index.php /var/www/html/index.php
RUN chmod a+rx index.php
```

index.php:
```php
<?php
  $x = 0.0001;
  for ($i = 0; $i <= 1000000; $i++) {
    $x += sqrt($x);
  }
  echo "OK!";
?>
```

Build the image:
```shell
$ docker build .
```

Run the image:
```shell
$ kubectl run php-apache --image=k8s.gcr.io/hpa-example --requests=cpu=200m --expose --port=80
service/php-apache created
deployment.apps/php-apache created
```

## Create Horizontal Pod Autoscaler

The following command will create a Horizontal Pod Autoscaler that maintains between 1 and 10 replicas of the Pods controlled by the php-apache deployment that is created above. Roughly speaking, HPA will increase and decrease the number of replicas (via the deployment) to maintain an average CPU utilization across all Pods of 50% (since each pod requests 200 milli-cores by kubectl run, this means average CPU usage of 100 milli-cores).

```shell
$ kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
horizontalpodautoscaler.autoscaling/php-apache autoscaled
```

Check the status of the HPA:

```shell
$ kubectl get hpa
NAME         REFERENCE                     TARGET    MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache/scale   0% / 50%  1         10        1          2m
```
`MINPODS` means the minimum number of pods is 1 and `MAXPODS` means the maximum number of pods is 10 and current replicas is 1.

## Increase load

Start busybox container and visit `index.php` to increase the CPU load.

```shell
# create the pod
$ kubectl create -f busybox.yaml

# exec into the pod
$ kubectl exec -it busybox /bin/sh

# hit the index.php endpoint in a loop
$ while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done
```
If everything goes OK, we should see `OK!`s printed on the terminal endlessly.

Wait for a while and check the Pod load
```shell
$ kubectl get hpa
NAME         REFERENCE                     TARGET    MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache/scale   230% / 50%  1         10        1          2m
```

Check the deployment
```shell
$ kubectl get deployment php-apache
NAME         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
php-apache   10         4         4            4           19m
```
Also, `kubectl get pods` should show some pods are still creating.

## Stop load

Go back to the busybox container terminal and press `Ctrl + C` to stop the process. Wait for a few minutes and the load should go down and the deployment should scale down to 1 instance again.

## Reference

[Google Official Document](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
[Google Official Document](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)