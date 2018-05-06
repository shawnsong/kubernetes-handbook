# Setup HAProxy

## Install HAProxy
```shell
sudo yum install haproxy -y
```

## Configurations
The /etc/haproxy/haproxy.cfg configuration file is divided into the following sections:

* global

  Defines global settings such as the syslog facility and level to use for logging, the maximum number of concurrent connections allowed, and how many processes to start in daemon mode.

* defaults
  Defines default settings for subsequent sections.

* listen

  Defines a complete proxy, implicitly including the frontend and backend components.

* frontend
  Defines the ports that accept client connections.

* backend
  Defines the servers to which the proxy forwards client connections.



## Configure HAProxy

Add the following configuration into `/etc/haproxy/haproxy.cfg`

```shell

#---------------------------------------------------------------------
# Configure HAProxy for Kubernetes API Server
#---------------------------------------------------------------------
listen stats
  bind    *:9000
  mode    http
  stats   enable
  stats   hide-version
  stats   uri       /stats
  stats   refresh   30s
  stats   realm     Haproxy\ Statistics
  stats   auth      Admin:Password

############## Configure HAProxy Secure Frontend #############
frontend k8s-api-https-proxy
    bind :443
    mode tcp
    tcp-request inspect-delay 5s
    tcp-request content accept if { req.ssl_hello_type 1 }
    default_backend k8s-api-https

############## Configure HAProxy SecureBackend #############
backend k8s-api-https
    balance roundrobin
    mode tcp
    option tcplog
    option tcp-check
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server k8s-api-1 192.168.1.101:6443 check
    server k8s-api-2 192.168.1.102:6443 check
    server k8s-api-3 192.168.1.103:6443 check

############## Configure HAProxy Unsecure Frontend #############
frontend k8s-api-http-proxy
    bind :80
    mode tcp
    option tcplog
    default_backend k8s-api-http

############## Configure HAProxy Unsecure Backend #############
backend k8s-api-http
    mode tcp
    option tcplog
    option tcp-check
    balance roundrobin
    default-server inter 10s downinter 5s rise 2 fall 2 slowstart 60s maxconn 250 maxqueue 256 weight 100
    server k8s-api-1 192.168.1.101:8080 check
    server k8s-api-2 192.168.1.102:8080 check
    server k8s-api-3 192.168.1.103:8080 check

```

We can use this command to test our configuration file.
```shell
haproxy -c -V -f /etc/haproxy/haproxy.cfg
```

Start HAProxy
```shell
sudo systemctl start haproxy
```

Then we can visit `localhost:9000/stats` to see check the status of different servers.