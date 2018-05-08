# Setup Scheduler

There is not much to configure for this component. Just run below to start the scheduler component.


```shell
# export environment variables
source /usr/k8s/bin/env.sh

/usr/k8s/bin/kube-scheduler \
  --address=127.0.0.1 \
  --master=http://${MASTER_URL}:8080 \
  --leader-elect=true \
  --v=2
```