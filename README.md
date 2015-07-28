# pacemaker_docker
Docker containerization of the Pacemaker High Availability Cluster Manager


## Example Create Image
```
./pcmk_create_image.sh

Making Dockerfile
Making image
Sending build context to Docker daemon 90.62 kB
Sending build context to Docker daemon 
Step 0 : FROM centos:centos7
 ---> 7322fbe74aa5
Step 1 : RUN yum install -y net-tools pacemaker resource-agents pcs corosync which fence-agents-common sysvinit-tools
 ---> Using cache
 ---> 49a5cd611558
Step 2 : ADD /helper_scripts /usr/sbin
 ---> Using cache
 ---> 7cb6f0605422
Step 3 : ADD defaults/corosync.conf /etc/corosync/
 ---> Using cache
 ---> 0bdbf9168f7a
Step 4 : ENTRYPOINT /usr/sbin/pcmk_launch.sh
 ---> Using cache
 ---> 6b5c48968492
Successfully built 6b5c48968492
```
## Launch Image giving pacemaker access to docker socket.

Note the usage of -v to mount the host docker.sock file into the container
as well as the --net=host option which gives the container access to the
host's network devices.

We need the docker.sock file accessible so pacemaker can launch containers
on the host while pacemaker is living within a container.

We need the --net=host option set so pacemaker can bind to the host's static
local ip address. Even though pacemaker is running in a container, it is
associated with the host. Pacemaker is launching containers on the host and
in manyway represents the host.

```
docker run -d -P -v /var/run/docker.sock:/var/run/docker.sock --net=host  --name=pcmk_test 6b5c48968492
```

If you need pacemaker to be able to manage a VIP using the IPaddr2 resource,
then the --privileged=true option must be used. This gives pacemaker the ability
to modify the IP addresses associated with local network devices. 

```
docker run -d -P -v /var/run/docker.sock:/var/run/docker.sock --net=host --privileged=true --name=pcmk_test 26e53d8b4652
```

## Test that pacemaker is active
```
docker exec pcmk_test crm_mon -1
  Last updated: Fri Jul 24 21:50:20 2015
  Last change: Fri Jul 24 21:49:36 2015
  Stack: corosync
  Current DC: 8e1eae1a7d0b (1) - partition with quorum
  Version: 1.1.12-a14efad
  1 Nodes configured
  0 Resources configured

  Online: [ 8e1eae1a7d0b ]
```

## Test that container has access to host's docker instance
```
docker exec pcmk_test docker ps
  CONTAINER ID        IMAGE                 COMMAND                CREATED             STATUS              PORTS               NAMES
  8e1eae1a7d0b        56992a77e0a9:latest   "/bin/sh -c /usr/sbi   7 seconds ago       Up 6 seconds                            pcmk_test        
```

## Tell pcmk_test to launch a container on the host machine.
```
docker exec pcmk_test pcs property set stonith-enabled=false
docker exec pcmk_test pcs resource create mycontainer ocf:heartbeat:docker image=<some image name> run_cmd=<custom entry point>
```


