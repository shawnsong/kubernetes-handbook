# Kubernetes Tips

Pods cannot be deleted if it's host goes down (the host state becomes `NotReady` and Pods state become `Unknown`). This is an expected behavior since 1.5. Below command can be used to force delete the Pods:
```shell
kubectl delete pod <pod_name> --grace-period=0 --force
```
