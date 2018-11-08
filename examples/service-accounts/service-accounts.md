# Service Accounts

Service Accounts in Kubernetes are like users in other systems. When admin users interact with the cluster through `kubectl`, they are authenticated as admin users by the API Server. Containers running inside Pods can also interact with the API Server and the way to authencate containers/Pods, is via Service Accounts.

## Creating Service Accounts

A Service Account can be created by simply typing
```shell
$ kubectl create serviceaccount test-sa
```
or by providing a YAML file:

```shell
apiVersion: v1
kind: ServiceAccount
metadata:
  name: test-service-account
```

## Getting the Service Account:

When a Service Account is created, a Secret(token) is also created and assigned to it automatically.

```shell
$ kubectl describe sa test-sa
Name:                test-sa
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Mountable secrets:   test-sa-token-s7w8r
Tokens:              test-sa-token-s7w8r
Events:              <none>
```
In this case `test-sa-token-s7w8r` is the name of the Secret.

```shell
$ kubectl describe secret test-sa-token-s7w8r

Name:         test-sa-token-s7w8r
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name=test-sa
              kubernetes.io/service-account.uid=a8d0a1f7-d9c1-11e8-930f-a0481cdd910a

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1391 bytes
namespace:  7 bytes
token:      eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJkZWZhdWx0Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZWNyZXQubmFtZSI6InRlc3Qtc2EtdG9rZW4tczd3OHIiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC5uYW1lIjoidGVzdC1zYSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VydmljZS1hY2NvdW50LnVpZCI6ImE4ZDBhMWY3LWQ5YzEtMTFlOC05MzBmLWEwNDgxY2RkOTEwYSIsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDpkZWZhdWx0OnRlc3Qtc2EifQ.KllRntBmWZUCvN6nBeUQlKidvR2T8KTM3TlIm7cMJ0R2qiNE9hNa1SYNa9AmJMUShX8ZwsWRFP9voOiT8jsMfbj7qaaZBmkWOMy58CJ0_fscPa_5FkTGm9EyDjFcWt7psp7RpfxQB6pwB6q88dl-et13mK_xHMmpTAAUiXyJ5qFdEPfDlPHpgVPtL9kdPS0m8zJBz7dgeCq-9KW4kt06DSlQ55_KNs2-BGbsAUvcLxBJ2t1o1Kj_gzEJvEafppaihvCHm8y4qzC4CgdVzaJjj25PP1yNBLq7PI-pkiLMuJnFlYov4vOmoGssyV2V7hnSwrztI0cE9pHapDEHsLGf5g
```
