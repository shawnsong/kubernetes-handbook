# Setup etcd Cluster

## Introduction
We are going to setup a 3-node static TLS secured etcd cluster by using self signed certificates. We have the following config in /etc/hosts in each node:

| IP Address	| hostname	|
|---------------|-----------|
| 192.168.1.102	| etcd1     |
| 192.168.1.103	| etcd2     |
| 192.168.1.101	| etcd3     |

## Install etcd
Go to [https://github.com/coreos/etcd/releases](etcd)'s official release page and download the latest etcd version. This tutorial uses v3.2.9. 

> Note: please be aware that domain names/hostnames are not allowed for some of the flags such as `listen-peer-urls` so please only use IP Addresses to bootstrap the static cluster.

```shell
$ curl -O -L https://github.com/coreos/etcd/releases/download/v3.2.9/etcd-v3.2.9-linux-amd64.tar.gz
$ tar -xzvf etcd-v3.2.9-linux-amd64.tar.gz -C etcd
$ sudo cp etcd/etcd-v3.2.9-linux-amd64/etcd* /usr/k8s/bin
```

Before we setup a TLS secured cluster, we can quickly bootstrap a cluster without TLS to make sure the network is not blocked by firewalls on each node. Start etcd with following options on each node:
```shell
$ etcd --name infra0 --initial-advertise-peer-urls http://192.168.1.101:2380 \
  --listen-peer-urls http://192.168.1.101:2380 \
  --listen-client-urls http://192.168.1.101:2379,http://127.0.0.1:2379 \
  --advertise-client-urls http://192.168.1.101:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster infra0=http://192.168.1.101:2380,infra1=http://192.168.1.102:2380,infra2=http://192.168.1.103:2380 \
  --initial-cluster-state new

$ etcd --name infra1 --initial-advertise-peer-urls http://192.168.1.102:2380 \
  --listen-peer-urls http://192.168.1.102:2380 \
  --listen-client-urls http://192.168.1.102:2379,http://127.0.0.1:2379 \
  --advertise-client-urls http://192.168.1.102:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster infra0=http://192.168.1.101:2380,infra1=http://192.168.1.102:2380,infra2=http://192.168.1.103:2380 \
  --initial-cluster-state new

$ etcd --name infra2 --initial-advertise-peer-urls http://192.168.1.103:2380 \
  --listen-peer-urls http://192.168.1.103:2380 \
  --listen-client-urls http://192.168.1.103:2379,http://127.0.0.1:2379 \
  --advertise-client-urls http://192.168.1.103:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster infra0=http://192.168.1.101:2380,infra1=http://192.168.1.102:2380,infra2=http://192.168.1.103:2380 \
  --initial-cluster-state new
```

If the cluster starts without any problem, then the network is reachable between each node. We can safely proceed to next steps.

## Generate self-signed certificates

There are three different type of certificates: 
- **client certificate** is used to authenticate client by server. For example etcdctl, etcd proxy, fleetctl or docker clients.
- **server certificate** is used by server and verified by client for server identity. For example docker server or kube-apiserver.
- **peer certificate** is used by etcd cluster members as they communicate with each other in both ways.
We use cfssl to generate all certificates.
### Download & install cfssl

```shell
$ mkdir bin
$ curl -s -L -o bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
$ curl -s -L -o bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
$ chmod +x bin/{cfssl,cfssljson}
$ export PATH=$PATH:bin
```

Generate a root certificate first, as we are going to use the root certificate to sign other certificates

```shell
cfssl gencert --initca=true ca-csr.json | cfssljson --bare etcd-root-ca
```

### Generate certificates

#### Server certificate
``` sheel
$ echo '{"CN":"server ca","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config ca-config.json -profile=server -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare server
```
#### Peer certificates

```shell
$ echo '{"CN":"etcd1","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd1

$ echo '{"CN":"etcd2","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd2

$ echo '{"CN":"etcd3","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd3
```

#### Client certificate

```shell
$ echo '{"CN":"client","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=client -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1" - | cfssljson -bare client
```

#### Verify above certificates
```shell
$ openssl x509 -in etcd-root-ca.pem -text -noout
$ openssl x509 -in server.pem -text -noout
$ openssl x509 -in client.pem -text -noout
```

#### Bootstrap a single node etcd to do some simple testing
After all certificates are generated, we need to copy `etcd-root-ca.pem, server.pem, server.key` to all of the etcd nodes. We also need to copy `etcd*-key.pem, etcd*.pem` to each node respectively. The path of the certificates are in `/etc/etcd/ssl`. Also make sure the permission of private keys are changed to `600`. Because each of the steps above needs to be done very carefully and is very erro proning, instead of creating a cluster directly, I highly recommend to bootstrap a one node cluster to test if etcd is functional correctly. To bootstrap a single node etcd:
```shell
$ etcd --name infra0 --data-dir infra0  \
  --trusted-ca-file=/etc/etcd/ssl/etcd-root-ca.pem --cert-file=/etc/etcd/ssl/server.pem --key-file=/etc/etcd/ssl/server-key.pem --advertise-client-urls=https://127.0.0.1:2379 --listen-client-urls=https://127.0.0.1:2379
```
This should start up fine and we can send a PUT request to etcd via https 
```shell
$ curl --cacert /etc/etcd/ssl/etcd-root-ca.pem https://127.0.0.1:2379/v2/keys/foo -XPUT -d value=bar -v
```
Then we do another test by getting the value we just set
```shell
curl --cacert /etc/etcd/ssl/etcd-root-ca.pem https://127.0.0.1:2379/v2/keys/foo -XGET -v
```

If we can successfully perform above tests, we are safe to move on to next steps.

#### Bootstrap the cluster
We use below command to start the cluster
etcd1 (192.168.1.102)
```shell
$ etcd --name etcd1 \
  --initial-advertise-peer-urls https://192.168.1.102:2380 \
  --listen-peer-urls https://192.168.1.102:2380 \
  --listen-client-urls https://192.168.1.102:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.1.102:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster etcd1=https://192.168.1.102:2380,etcd2=https://192.168.1.103:2380,etcd3=https://192.168.1.101:2380 \
  --initial-cluster-state new \
  --cert-file /etc/etcd/ssl/server.pem \
  --key-file /etc/etcd/ssl/server-key.pem \
  --client-cert-auth="true" \
  --trusted-ca-file /etc/etcd/ssl/etcd-root-ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd1.pem \
  --peer-key-file=/etc/etcd/ssl/etcd1-key.pem \
  --peer-client-cert-auth="true" \
  --peer-trusted-ca-file=/etc/etcd/ssl/etcd-root-ca.pem \
  --data-dir /var/lib/etcd
```
etcd2 (192.168.1.103)
```shell
$ etcd --name etcd2 \
  --initial-advertise-peer-urls https://192.168.1.103:2380 \
  --listen-peer-urls https://192.168.1.103:2380 \
  --listen-client-urls https://192.168.1.103:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.1.103:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster etcd1=https://192.168.1.102:2380,etcd2=https://192.168.1.103:2380,etcd3=https://192.168.1.101:2380 \
  --initial-cluster-state new \
  --cert-file /etc/etcd/ssl/server.pem \
  --key-file /etc/etcd/ssl/server-key.pem \
  --client-cert-auth="true" \
  --trusted-ca-file /etc/etcd/ssl/etcd-root-ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd2.pem \
  --peer-key-file=/etc/etcd/ssl/etcd2-key.pem \
  --peer-client-cert-auth="true" \
  --peer-trusted-ca-file=/etc/etcd/ssl/etcd-root-ca.pem \
  --data-dir /var/lib/etcd
```
etcd3 (192.168.1.101)
```shell
$ etcd --name etcd3 \
  --initial-advertise-peer-urls https://192.168.1.101:2380 \
  --listen-peer-urls https://192.168.1.101:2380 \
  --listen-client-urls https://192.168.1.101:2379,https://127.0.0.1:2379 \
  --advertise-client-urls https://192.168.1.101:2379 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-cluster etcd1=https://192.168.1.102:2380,etcd2=https://192.168.1.103:2380,etcd3=https://192.168.1.101:2380 \
  --initial-cluster-state new \
  --cert-file /etc/etcd/ssl/server.pem \
  --key-file /etc/etcd/ssl/server-key.pem \
  --client-cert-auth="true" \
  --trusted-ca-file /etc/etcd/ssl/etcd-root-ca.pem \
  --peer-cert-file=/etc/etcd/ssl/etcd3.pem \
  --peer-key-file=/etc/etcd/ssl/etcd3-key.pem \
  --peer-client-cert-auth="true" \
  --peer-trusted-ca-file=/etc/etcd/ssl/etcd-root-ca.pem \
  --data-dir /var/lib/etcd
```
When the three nodes are all up, we should see message 'established a TCP streaming connection with peer 4469cb53324fe68b' on each node. Then we can test the cluster by **set** a value to one node (etcd1)
```shell
$ curl --cacert /etc/etcd/ssl/etcd-root-ca.pem etcd-root-ca.pem --cert ./client.pem --key ./client-key.pem -L https://etcd1:2379/v2/keys/foo -XPUT -d value=bar -v
```
and **get** the value from a different node (etcd2 or etcd3)
```shell
$ curl --cacert /etc/etcd/ssl/etcd-root-ca.pem --cert ./client.pem --key ./client-key.pem -L https://etcd2:2379/v2/keys/foo -XGET -v
```
Or we can use etcdctl
```shell
$ export ETCDCTL_API=3
$ etcdctl --endpoints=https://etcd1:2379 --cacert=/etc/etcd/ssl/etcd-root-ca.pem --cert=./client.pem --key=./client-key.pem endpoint health
```
### TL DR
- Download & install cfssl
```shell
$ mkdir ~/bin
$ curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
$ curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
$ chmod +x ~/bin/{cfssl,cfssljson}
$ export PATH=$PATH:~/bin
```
- Generate a root CA
```shell
$ cfssl gencert --initca=true ca-csr.json | cfssljson --bare etcd-root-ca
```
- Generate server certificate
``` sheel
$ echo '{"CN":"server ca","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config ca-config.json -profile=server -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare server
```

- Generate peer certificate
```shell
$ echo '{"CN":"etcd1","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd1

$ echo '{"CN":"etcd2","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd2

$ echo '{"CN":"etcd3","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd3
```
- Generate client certificate

```shell
$ echo '{"CN":"client","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=client -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1" - | cfssljson -bare client
```
- Verify certificates
```shell
$ openssl x509 -in etcd-root-ca.pem -text -noout
$ openssl x509 -in server.pem -text -noout
$ openssl x509 -in client.pem -text -noout
```
- Bootstrap the cluster <br />
 See above

### etcd commands
```shell
# Display all keys
$ export ETCDCTL_API=3 
$ etcdctl --endpoints=https://etcd1:2379 --cacert=/etc/etcd/ssl/etcd-root-ca.pem --cert=./client.pem --key=./client-key.pem get / --prefix --keys-only
```
