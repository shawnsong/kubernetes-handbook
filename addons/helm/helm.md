# Helm User Guide

Helm for Kubernetes is similar to Yum for RedHat Linux. It is a package management tool specifically for Kubernetes to version control the releases of applications running in the cluster. Helm is consisted of two components: the Helm client and the Tiller server.

## Install Helm


## Install Tiller


Run `helm version` to see the currently installed version of Helm and Tiller. If you see an error like this:
```shell
unable to do port forwarding: socat not found.`
```
Install `socat` on all Kubernetes nodes by running:
```shell
$ sudo yum install socat
```

## Lsit Helm Charts

To list Helm installed charts: 
```shell
$ helm ls
```

It is possible to see this error:
```shell
Error: configmaps is forbidden: User "system:serviceaccount:kube-system:default" cannot list configmaps in the namespace "kube-system"
```

It means Helm does not have permission to run command in `kube-system` namespace so we need to create the RBAC for Helm first. Run the following commands directly to create RBAC rules:

```shell
$ kubectl create serviceaccount --namespace kube-system tiller
$ kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
$ kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'s
$ helm init --service-account tiller --upgrade
```
or use the yaml files:

```shell
$ kubectl create -f helm-access.yaml
# serviceaccount "tiller-serviceaccount" created
# clusterrolebinding "tiller-cluster-role-binding" created
$ kubectl patch deploy --namespace kube-system tiller-deploy --patch "$(cat helm-access-patch.yaml)"
# deployment "tiller-deploy" patched
```


