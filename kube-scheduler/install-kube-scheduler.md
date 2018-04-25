```shell
/usr/k8s/bin/kube-scheduler \
  --address=127.0.0.1 \
  --master=http://${MASTER_URL}:8080 \
  --leader-elect=true \
  --v=2
```