# Metrics Servers

Metrics Server is a cluster resource usage data aggregator for Kubernetes cluster. It is a replacement of Heapster since 1.8.

## Setup API Server

Make sure API Server is able to communicate to Pods (firewall on worker nodes needs to allow port 443 for TCP connection, I also have flannel running on API Servers)

### Create SSL Certificates

`ca-config.json` is copied from [here](../../../ssl/ca-config.json).
```shell
$ cfssl gencert --initca=true aggregator-ca-csr.json | ssljson --bare aggregator-ca

$ echo '{"CN":"client","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=aggregator-ca.pem -ca-key=aggregator-ca-key.pem -config=ca-config.json -profile=client - | cfssljson -bare aggregator-proxy-client
```

Then copy the generated certificates to `/etc/kubernetes/ssl/aggregator-ca/` folder.

### Enable API Server Options
Before deploying metrics-server, API Aggregation needs to be enabled in API Server.
```shell
--requestheader-client-ca-file=/etc/kubernetes/ssl/aggregator-ca/aggregator-ca.pem
--requestheader-allowed-names=front-proxy-client
--requestheader-extra-headers-prefix=X-remote-Extra- 
--requestheader-group-headers=X-Remote-Group 
--requestheader-username-headers=X-Remote-User 
--proxy-client-cert-file=/etc/kubernetes/ssl/aggregator-ca/aggregator-proxy-client.pem 
--proxy-client-key-file=/etc/kubernetes/ssl/aggregator-ca/aggregator-proxy-client-key.pem 
--enable-aggregator-routing=true
```
Add the following configs to `apiserver`.
```shell
# Aggregation layer configs
AGGREGATION_LAYER_CONFIG="--requestheader-client-ca-file=/etc/kubernetes/ssl/aggregator-ca/aggregator-ca.pem --requestheader-allowed-names=front-proxy-client --requestheader-extra-headers-prefix=X-remote-Extra- --requestheader-group-headers=X-Remote-Group --requestheader-username-headers=X-Remote-User --proxy-client-cert-file=/etc/kubernetes/ssl/aggregator-ca/aggregator-proxy-client.pem --proxy-client-key-file=/etc/kubernetes/ssl/aggregator-ca/aggregator-proxy-client-key.pem --enable-aggregator-routing=true"
```
> **Note:** Make sure the certificate CommonName (CN) value is aligned with the value in `--requestheader-allowed-names` (front-proxy-client)

### Deploy Metrics Server

In this tutorial, I need to modify `metrics-server-deployment.yaml` to add two arguments:
```shell
- /metrics-server
 --requestheader-client-ca-file--kubelet-preferred-address-types=InternalIP
 --requestheader-client-ca-file--kubelet-insecure-tls
```

### Verify Metrics Server is Working
```shell
$ kubectl top nodes
```
This should return CPU/Memory usage data.

### Trouble Shooting
The installation of Metrics Server could be problematic. Here are a few tips to diagnose issues:
- Make sure `metrics-server` is running in `kube-system` systems. Use `kubectl logs` to check causes. It could be caused by certificates issues. If that's the case, make sure the generated certificates are distributed to all API Servers.
- Make sure the Pod is reachable from other nodes. Ping the Pod should return results.
- Make sure the Metrics `APIService` is running. `kubectl get apiservice` 
- If the Pod is running but `kubectl top` returns errors like `Error from server (ServiceUnavailable): the server is currently unable to handle the request`, check API Server logs: `journal -u kube-apiserver -f` or add '`v=10` in the `kubectl top` command to find out it fails at what step.