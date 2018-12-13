# Metrics Servers

Metrics Server is a cluster resource usage data aggregator for Kubernetes cluster. It is a replacement of Heapster since 1.8.


Tips:
- Make sure API Server is able to communicate to Pods (flannel running on API Server)
- Enable API Server options
- Make sure the certificate CommonName (CN) value is aligned with the value in `--requestheader-allowed-names` (front-proxy-client)
- modify `metrics-server-deployment.yaml` :
```shell
- /metrics-server
        - --kubelet-preferred-address-types=InternalIP
        - --kubelet-insecure-tls
```
