# Secrets

Secrets in Kubernetes is to provide a means to pass credentials to the Pods. Secrets is a a Kubernetes native to get credentials, third party Vault services can also be used as credential store for the apps.

Secrets can be used as:
- Environment variables of a Pod
- Files within a Pod
	- A volumn needs to be mounted to the Pod
	- The secret files are in the volumn

Create secrets using files:
```shell
$ echo "admin" > username.txt
$ echo "password" > password.txt
$ kubectl create secret generic db-user-pass --from-file=./username.txt --from-file=./password.txt
# secret "db-user-pass" created
```

Create secrets using yaml files:
```shell
$ kubectl create -f db-secret.yaml
```

Get secrets from Kubernets:
```shell
$ kubectl get secret db-user-pass -o yaml
$ kubectl get secret db-user-pass -o yaml
```