# Setup CoreDNS

CoreDNS is a replacement for KubeDNS since Kubernetes v1.10. CoreDNS has provided a script to replace the currently running KubeDNS in the cluster. The script uses `coredns.yaml.sed` as a template to create the ConfigMap and CoreDNS deployment. It reuses the KubeDNS service to provide a zero down time transformation. The script is also able to retrieve the KubeDNS configs and apply it to CoreDNS. The script does not delete the old KubeDNS deployment so that needs to be done manually.

```shell
# create CoreDNS deployment
$ ./deploy.sh | kubectl apply -f -
# delete KubeDNS
$ kubectl delete --namespace=kube-system deployment kube-dns
```