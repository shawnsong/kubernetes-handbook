# Setup Scheduler

The kube-scheduler execution file is copied to /usr/k8s/bin when we were installing the api-server so we can start the scheduler directly.

## Start kube-scheduler
```shell
# Export environment variables
source /usr/k8s/bin/env.sh

/usr/k8s/bin/kube-scheduler \
  --address=127.0.0.1 \
  --master=http://${MASTER1_IP}:8080 \
  --leader-elect=true \
  --v=2
```

## Point Scheduler to the HAProxy
We can let `kube-controller-manager` points to the virtual IP of HAProxy directly: `192.168.1.201`, or we can use the hostname: `k8s-api.virtual.local`. 

```shell
# MASTER_URL is defined in env.sh
export KUBE_APISERVER="https://${MASTER_URL}"
  --master=http://${KUBE_APISERVER} \
```
We removed the 8080 port number from the server URL because HAProxy will redirect HTTP request to 8080.