# Pod Presets

A Kubernetes cluster may contain hundreds of Pods. Many of these Pods share common data like Environment Variables, ConfigMaps, Secrets etc. For instance, in case of microservices communicating over ActiveMQ, the connection information needs to be injected into each microservice. If the cluster has a lot microservices (each microservice could be 1 Pods), each Pod needs to have a section referencing the ActiveMQ ConfigMap in their Pod definition. This is terribly inefficient and error prone. Pod Preset helps to mitigate this by injecting common information in multiple Pods so that all common information are put in one place.


## What is Pod Preset

Pod Preset is Used for injecting common information to all Pods at creation time. It need to be enabled explicitly in Kubernetes API server configuration. According to [Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/pods/podpreset/#enable-pod-preset), to enable Pod Preset, `--runtime-config` needs to have`settings.k8s.io/v1alpha1=true` and `--enable-admission-plugins` needs to contain `PodPreset`.

Label selectors can be used to filter the pods on which Pod Presets are applicable. This is useful when you don't want to apply preset to all pods.

## Enable Pod Preset in the Cluster
Pod Preset is not enabled by default, to enable it in the cluster, the following needs to be done:

1. Enable the API type settings.k8s.io/v1alpha1/podpreset. This can be done by including settings.k8s.io/v1alpha1 in the `--runtime-config`: `--runtime-config=settings.k8s.io/v1alpha1`
2. Enable admission controller `PodPreset`: `--admission-control=...,PodPreset,...`

## Pod Preset Examples

Below is an example of how Pod Preset can help to concise Pod configurations.

### Step 1 : Create Kubernetes Secret
This step is common for both old way of injecting information and new way of using PodPreset.
```shell
apiVersion: v1
kind: Secret
metadata:
  name: activemq-secret
type: Opaque
data:
  # echo "admin" | base64
  username: YWRtaW4K 
  # echo "password" | base64
  password: cGFzc3dvcmQK
```
### Step 2 : Inject Secret into Pod
#### 2.1 : Old and Inefficient Way
To use the above secret in Pod, we need to put following configuration in pod.
```shell
# Microservice-one
apiVersion: v1
kind: Pod
metadata:
  name: Microservice-one
spec:
  containers:
  - name: mycontainer
    image: nginx:latest
    env:
      - name: SECRET_USERNAME
        valueFrom:
          secretKeyRef:
            name: activemq-secret
            key: username
      - name: SECRET_PASSWORD
        valueFrom:
          secretKeyRef:
            name: activemq-secret
            key: password
  restartPolicy: Never
```
Notice that the `env` section needs to be done in every microservice that is using ActiveMQ. If there are 10 microservices in the system that are using ActiveMQ (which is not uncommon at all), that section needs to be repeated 10 times.

#### 2.2 Using Pod Preset
- Create a Pod Preset yaml : Following example creates Pod Preset for RabbitMQ secret. Label selector will make sure that this Preset is applied to pods with label role = worker

apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-database
spec:
  selector:
    matchLabels:
      role: business-service
  env:
    - name: SECRET_USERNAME
      valueFrom:
        secretKeyRef:
          name: mysecret
          key: rabbit-username
    - name: SECRET_PASSWORD
      valueFrom:
        secretKeyRef:
          name: mysecret
          key: rabbit-password

- Create one or more ( 10s of) Pod configurations with label role: business-service.

apiVersion: v1
kind: Pod
metadata:
  name: Microservice-one
  labels:
    role: worker
spec:
  containers:
    - name: website
      image: nginx
      ports:
        - containerPort: 80
All the pods matching the labels will have RabbitMQ secret injected.

Conclusion
Pod Preset is a very powerful mechanism for injecting common information into Pods. Similar to secrets injected in above example, we could inject other information such as ConfigMaps, Volumes etc.
