# Setup Keepalived

The `/etc/keepalived/keepalived.conf` configuration file is divided into the following sections:

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


## Configuring Simple Virtual IP Address Failover Using Keepalived
A typical Keepalived high-availability configuration consists of one master server and one or more backup servers. One or more virtual IP addresses, defined as VRRP instances, are assigned to the master server's network interfaces so that it can service network clients. The backup servers listen for multicast VRRP advertisement packets that the master server transmits at regular intervals. The default advertisement interval is one second. If the backup nodes fail to receive three consecutive VRRP advertisements, the backup server with the highest assigned priority takes over as the master server and assigns the virtual IP addresses to its own network interfaces. If several backup servers have the same priority, the backup server with the highest IP address value becomes the master server.

