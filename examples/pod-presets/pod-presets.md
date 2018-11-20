# Pod Presets

A Kubernetes cluster may contain hundreds of Pods. Many of these Pods share common data like Environment Variables, ConfigMaps, Secrets etc. For instance, in case of microservices communicating over ActiveMQ, the connection information needs to be injected into each microservice. If the cluster has a lot microservices (each microservice could be 1 Pods), each Pod needs to have a section referencing the ActiveMQ ConfigMap in their Pod definition. This is terribly inefficient and error prone. Pod Preset helps to mitigate this by injecting common information in multiple Pods so that all common information are put in one place.


What is Pod Preset
Used for injecting common information to all Pods at creation time
Currently in alpha stage. Need to be enabled explicitly in Kubernetes API server configuration [ See here ]
Applicable to Kubernetes constructs Env, EnvFrom, and VolumeMounts in the PodSpec.
Label selectors can be used to filter the pods on which Pod Presets are applicable. This is useful when you don't want to apply preset to all pods.
Let's take above example of RabbitMQ secret and see how Pod Presets makes our life easy.

Step 1 : Create Kubernetes Secret
This step is common for both old way of injecting information and new way of using Preset.

apiVersion: v1
kind: Secret
metadata:
  name: mysecret
type: Opaque
data:
  rabbit-username: YWRtaW4=
  rabbit-password: MWYyZDFlMmU2N2Rm
Step 2 : Inject Secret into Pod
2.1 : Old and Inefficient Way
To use the above secret in Pod, we need to put following configuration in pod.

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
We need to do this in every microservice !

2.2 Using Pod Preset
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
