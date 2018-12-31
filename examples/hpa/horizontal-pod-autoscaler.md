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

## Reference

[Google Official Document](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)