# Setup Nginx

## Install Nginx
```shell
sudo yum install nginx -y
```

## Configure Nginx
There are a few places you can put the configuration files. In this tutorial, we are going to use the simplest way to configure it. Open `/etc/nginx/nginx.conf` and add the following configuration.

```shell
stream {
    upstream kube_apiserver {
        least_conn;
        server 192.168.1.101:6443;
        server 192.168.1.102.2:6443;
        server 192.168.1.103:6443;
    }

    server {
        listen        0.0.0.0:6443;
        proxy_pass    kube_apiserver;
        proxy_timeout 10m;
        proxy_connect_timeout 1s;
    }
}
```
