# Setup Keepalived

Keepalived uses the IP Virtual Server (IPVS) kernel module to provide transport layer (Layer 4) load balancing,  redirecting requests for network-based services to individual members of a server cluster. IPVS monitors the status of each server and uses the Virtual Router Redundancy Protocol (VRRP) to achieve high availability.

## Install Keepalived

```shell
sudo yum install keepalived
```

After the installation, a configuration file will be created at `/etc/keepalived/keepalived.conf`. This configuration file is divided into the following sections:

- **global_defs:** 
	Defines global settings such as the email addresses for sending notification messages, the IP address of an SMTP server, the timeout value for SMTP connections in seconds, a string that identifies the host machine, the VRRP IPv4 and IPv6 multicast addresses, and whether SNMP traps should be enabled.

- **static_ipaddress, static_routes:** 
	Define static IP addresses and routes, which VRRP cannot change. These sections are not required if the addresses and routes are already defined on the servers and these servers already have network connectivity.

- **vrrp_sync_group:** 
	Defines a VRRP synchronization group of VRRP instances that fail over together.

- **vrrp_instance:** 
	Defines a moveable virtual IP address for a member of a VRRP synchronization group's internal or external network interface, which accompanies other group members during a state transition. Each VRRP instance must have a unique value of virtual_router_id, which identifies which interfaces on the master and backup servers can be assigned a given virtual IP address. You can also specify scripts that are run on state transitions to BACKUP, MASTER, and FAULT, and whether to trigger SMTP alerts for state transitions.

- **vrrp_script:**
	Defines a tracking script that Keepalived can run at regular intervals to perform monitoring actions from a vrrp_instance or vrrp_sync_group section.

- **virtual_server_group:** 
	Defines a virtual server group, which allows a real server to be a member of several virtual server groups.

- **virtual_server:** 
	Defines a virtual server for load balancing, which is composed of several real servers.


## Configure Simple Virtual IP Address Failover Using Keepalived
A typical Keepalived high-availability configuration consists of one master server and one or more backup servers. One or more virtual IP addresses, defined as VRRP instances, are assigned to the master server's network interfaces so that it can service network clients. The backup servers listen for multicast VRRP advertisement packets that the master server transmits at regular intervals. The default advertisement interval is one second. If the backup nodes fail to receive three consecutive VRRP advertisements, the backup server with the highest assigned priority takes over as the master server and assigns the virtual IP addresses to its own network interfaces. If several backup servers have the same priority, the backup server with the highest IP address value becomes the master server.

```shell
# Enable IP forwarding
echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
# Enable Packet Forwarding and Nonlocal Binding
echo "net.ipv4.ip_nonlocal_bind = 1" >> /etc/sysctl.conf
# Verify the settings
sysctl -p
# Output should be
net.ipv4.ip_forward = 1
net.ipv4.ip_nonlocal_bind = 1
```

Use the following configuration for `/etc/keepalived/keepalived.conf` on the master server which is **192.168.1.101** in this tutorial. 

```shell
global_defs {
   notification_email {
     
   }
}

vrrp_instance haproxy-virtual-ip {
    state MASTER

#   Make sure the interface is aligned with your server's network interface
    interface enp0s3 

#   The virtual router ID must be unique to each VRRP instance that you define
    virtual_router_id 51
    
#   Make sure the priority is higher on the master server than on backup servers
    priority 200 

#   advertisement interval, 1 second
    advert_int 1

    authentication {
        auth_type PASS
        auth_pass 1066
    }

    virtual_ipaddress {
        192.168.1.201/24
    }
}
```

Copy the above file to the backup server **192.168.1.102** and make the following changes:
1. Change the `state` to `BACKUP`
2. Change the `priority` to a lower value, `150`

After this setup, we can do a simple testing before moving on to the next steps. It is a good practice to keep testing your configurations while you are modifying them. This helps a lot to narrow down where problems are so we can correct them as early as possible.

```shell
# Start the service on both servers
sudo systemctl start keepalived

# Check the ip address on master
ip addr show
# The output should be similar to the following
2: enp0s3: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP qlen 1000
    link/ether 08:00:27:5e:b0:3f brd ff:ff:ff:ff:ff:ff
    inet 192.168.1.101/24 brd 192.168.1.255 scope global enp0s3
       valid_lft forever preferred_lft forever
    inet 192.168.1.201/24 scope global secondary enp0s3
       valid_lft forever preferred_lft forever
    inet6 fd50:4b8:60a3:be00:8bdc:d13d:b7f6:4573/64 scope global noprefixroute dynamic
       valid_lft 7053sec preferred_lft 3453sec
    inet6 fe80::17a6:9275:98fb:6f4/64 scope link
       valid_lft forever preferred_lft forever
```
We can see there are two ip address bind to the network interface. We can ping the virtual ip from a different server (etcd2). Please note that the virtual ip is in the same network with the master's real ip address. If we configure the virtual ip in a different network, i.e 192.168.100.101, then we cannot ping it from etcd2.

If we stop keepalived on master, the virtual ip will be *shifting* to the backup server. This can be verified by using above command on the backup server.

> **Note**  
> There should always be ONLY one server active as the master at any point in time. If the master is failed, the backup server with highest prority number will takeover the master role until the master has come back up. If more than one servers are configured with same priority number, then the server with highest ip address will be the master.

## Configure Load Balancing Using Keepalived in NAT Mode
The next step is to setup Keepalived in NAT mode to implement a simple failover and load balancing configuration on two servers. Add the following content to the configure files.

```shell
virtual_server 192.168.100.101 80 {
    delay_loop 6
    lb_algo rr
    lb_kind NAT
    persistence_timeout 50
    protocol TCP

    real_server 192.168.1.101 80 {
        weight 1
        TCP_CHECK {
        connect_port 80
        connect_timeout 3
      }
    }

    real_server 192.168.1.102 80 {
        weight 1
        TCP_CHECK {
        connect_port 80
        connect_timeout 3
      }
    }
}

virtual_server 192.168.100.101 443 {
    delay_loop 6
    lb_algo rr
    lb_kind NAT
    persistence_timeout 05
    protocol TCP

    real_server 192.168.1.101 443 {
        weight 1
        TCP_CHECK {
        connect_port 443
        connect_timeout 3
      }
    }

    real_server 192.168.1.102 443 {
        weight 1
        TCP_CHECK {
        connect_port 443
        connect_timeout 3
      }
    }
}
```