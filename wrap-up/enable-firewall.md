# Wrap Up

## Enable Firewalls
So far, we have our firewall disabled on all our master nodes so it does not disturb our setup process. It is time to turn it on.

```shell
# Start firewalld on each master node
sudo systemctl start firewalld

# Check the firewalld running status
sudo firewall-cmd --state
running

# Check the rules
sudo firewall-cmd --list-all

# should return something similar to this
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens33
  sources: 
  services: dhcpv6-client ssh
  ports: 
  protocols: 
  masquerade: no
  forward-ports: 
  sourceports: 
  icmp-blocks: 
  rich rules: 
```

Now if we tried to access the masters `http://192.168.1.101` from a different node, we should get connection refused error. 

Also, if we check the haproxy statistics on masternode1, we should notice that `k8s-api2` and `k8s-api3` are all down. In our HA architecture, the happroxy needs to be able to visit all API Servers. Therefore, we want to limit our API Servers only accessable from our master nodes `(192.168.1.101, 192.168.1.102, 192.168.1.103)`. We use firewalld rich rules to limit 8080 and 6443 only open to the master nodes.

On master node 1:
```shell
# Enable access from masternode2
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.102" port protocol="tcp" port="8080" accept'
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.102" port protocol="tcp" port="6443" accept'
# Enable access from masternode3
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.103" port protocol="tcp" port="8080" accept'
sudo firewall-cmd --zone=public --add-rich-rule='rule family="ipv4" source address="192.168.1.103" port protocol="tcp" port="6443" accept'
```

