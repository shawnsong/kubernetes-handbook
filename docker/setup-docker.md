# Setup Docker

## Install Docker

The easist way to install docker is via `yum`. Make sure the version of Docker should be later than 1.12.

## Verify Docker Environment File

In the previous step when flannel was installed, `mk-docker-opts.sh` was copied to `/usr/k8s/bin`. This file is used to generate Docker config file when flannel starts up. The generated file is located inside `/run/flannel/` folder.

There are two files in the folder:

- /run/flannel/subnet.env
```shell
FLANNEL_NETWORK=172.30.0.0/16
FLANNEL_SUBNET=172.30.17.1/24
FLANNEL_MTU=1450
FLANNEL_IPMASQ=false
```

- /run/flannel/docker
```shell
DOCKER_OPT_BIP="--bip=172.30.17.1/24"
DOCKER_OPT_IPMASQ="--ip-masq=true"
DOCKER_OPT_MTU="--mtu=1450"
DOCKER_NETWORK_OPTIONS=" --bip=172.30.17.1/24 --ip-masq=true --mtu=1450"
```

> Note: the file name might be slightly different depending on the version of flannel. The content should be very similar but with different values.

## Configure Docker

We need to apply those configurations file when Docker starts so the container can be created in flannel network. To achieve that, we can simply edit docker systemd unit file located at `/usr/lib/systemd/system/docker.service`. But as a good practice, it is better to leave the original systemd file and use `systemctl edit xxxx` instead to add the things you want. I personally prefer useing `systemctl edit --full` to edit the systemd unit file. In this case, a new unit file with exactly the same name will be created under `/etc/systemd/system` folder. Any file placed there which has the same name as a file installed by a package manager in /usr/lib/systemd/system/, will take precedence.

```shell
sudo systemctl edit --full docker.service

# Add the environment files
EnvironmentFile=-/run/flannel/subnet.env
EnvironmentFile=-/run/flannel/docker

# And the docker.service file should look like
EnvironmentFile=-/run/flannel/subnet.env
EnvironmentFile=-/run/flannel/docker
EnvironmentFile=-/run/containers/registries.conf
EnvironmentFile=-/etc/sysconfig/docker
EnvironmentFile=-/etc/sysconfig/docker-storage
EnvironmentFile=-/etc/sysconfig/docker-network
```

Restart docker.