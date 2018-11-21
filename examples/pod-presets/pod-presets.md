# Pod Presets

A Kubernetes cluster may contain hundreds of Pods. Many of these Pods share common data like Environment Variables, ConfigMaps, Secrets etc. For instance, in case of microservices communicating over ActiveMQ, the connection information needs to be injected into each microservice. If the cluster has a lot microservices (each microservice could be 1 Pods), each Pod needs to have a section referencing the ActiveMQ ConfigMap in their Pod definition. This is terribly inefficient and error prone. Pod Preset helps to mitigate this by injecting common information in multiple Pods so that all common information are put in one place.


## What is Pod Preset

Pod Preset is Used for injecting common information to all Pods at creation time. It need to be enabled explicitly in Kubernetes API server configuration. According to [Kubernetes Docs](https://kubernetes.io/docs/concepts/workloads/pods/podpreset/#enable-pod-preset), to enable Pod Preset, `--runtime-config` needs to have`settings.k8s.io/v1alpha1=true` and `--enable-admission-plugins` needs to contain `PodPreset`.

Label selectors can be used to filter the pods on which Pod Presets are applicable. This is useful when you don't want to apply preset to all pods.

## Pod Preset Examples

Below is an example of how Pod Preset can help to concise Pod configurations.

### Step 1 : Create Kubernetes Secret
This step is common for both old way of injecting information and new way of using Preset.
```shell
apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  rabbit-username: YWRtaW4=
  rabbit-password: MWYyZDFlMmU2N2Rm
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
            name: mysecret
            key: rabbit-username
      - name: SECRET_PASSWORD
        valueFrom:
          secretKeyRef:
            name: mysecret
            key: rabbit-password
  restartPolicy: Never
```
This needs to be done in every microservice.

#### 2.2 Using Pod Preset
a] Create a Pod Preset yaml : Following example creates Pod Preset for RabbitMQ secret. Label selector will make sure that this Preset is applied to pods with label role = worker

apiVersion: settings.k8s.io/v1alpha1
kind: PodPreset
metadata:
  name: allow-database
spec:
  selector:
    matchLabels:
      role: worker
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
b] Create one or more ( 100s of) Pod configurations with label role: worker.

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
