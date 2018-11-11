# ConfigMaps

Configuration parameters that are not secrets of a Pod can be put into ConfigMaps. It is a key-value store. It can be accessed inside containers via **environment variables**, **container commandline arguments** or using **volumes**.

ConfigMaps can also store files. In that case, full configuration files can be stored in ConfigMaps and therefore can be *injected* into containers dynamically. 

## Creating ConfigMaps
```shell
$ kubectl create configmap springboot-config --from-file=application.properties
```

## Using ConfigMaps

### Using ConfigMaps as Mounted Volumes
```shell
$ kubectl create -f file-configmap-pod.yaml
```

### Using ConfigMaps as Environment Variables

```shell
$ kubectl create -f env-configmap-pod.yaml

$ kubectl exec -it busybox-config-in-env sh
# inside the container
$ env
serverPort=server.port=9090
spring.application.name=demoservice
```