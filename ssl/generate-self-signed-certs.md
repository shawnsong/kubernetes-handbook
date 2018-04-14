## Generate self-signed certificates

We use cfssl to generate all certificates.

### Download cfssl

``` shell
mkdir ~/bin
curl -s -L -o ~/bin/cfssl https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
curl -s -L -o ~/bin/cfssljson https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
chmod +x ~/bin/{cfssl,cfssljson}
export PATH=$PATH:~/bin
```

- **client certificate** is used to authenticate client by server. For example etcdctl, etcd proxy, fleetctl or docker clients.
- **server certificate** is used by server and verified by client for server identity. For example docker server or kube-apiserver.
- **peer certificate** is used by etcd cluster members as they communicate with each other in both ways.

cfssl gencert --initca=true ca-csr.json | cfssljson --bare etcd-root-ca

### for server certificates
echo '{"CN":"server ca","hosts":[""],"key":{"algo":"rsa","size":2048} }' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config ca-config.json -profile=server -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare server


### for peer certificates

``` shell
echo '{"CN":"etcd1","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd1

echo '{"CN":"etcd2","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd2

echo '{"CN":"etcd3","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=peer -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare etcd3
```

### verify certificates

openssl x509 -in etcd-root-ca.pem -text -noout
openssl x509 -in server.pem -text -noout
openssl x509 -in client.pem -text -noout


### for client certificates

echo '{"CN":"client","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config=ca-config.json -profile=client -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1" - | cfssljson -bare client

### for server certificate
echo '{"CN":"server ca","hosts":[""],"key":{"algo":"rsa","size":2048}}' | cfssl gencert -ca=etcd-root-ca.pem -ca-key=etcd-root-ca-key.pem -config ca-config.json -profile=server -hostname="192.168.1.101,192.168.1.102,192.168.1.103,127.0.0.1,etcd1,etcd2,etcd3" - | cfssljson -bare server