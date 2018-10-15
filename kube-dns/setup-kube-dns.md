# Setup Kube DNS

`kube-dns` is a Kubernetes plugin that helps Pods find other Services/Pods by domain names. It is just required to create a Pod and a Service to install this plugin. 

Run below command to install the plugin:
```shell
kubectl create -f kubedns.yaml
```

This is the [link](./kubedns.yaml) to the file.