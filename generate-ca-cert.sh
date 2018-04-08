export PATH=/usr/k8s/bin:$PATH

#mkdir ssl && chown $USER:$USER ssl cd ssl
#cfssl print-defaults config > config.json
#cfssl print-defaults csr > csr.json

cd ssl

# generate cert
cfssl gencert -initca ca-csr.json | cfssljson -bare ca

# distribute the certs to the below folder in all nodes
sudo mkdir -p /etc/kubernetes/ssl
sudo cp ca* /etc/kubernetes/ssl


cfssl gencert -initca ca-csr.json | cfssljson -bare ca
sudo mkdir -p /etc/kubernetes/ssl
sudo cp ca* /etc/kubernetes/ssl
