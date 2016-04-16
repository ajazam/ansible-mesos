####Mesos installation using Ansible with Zookeeper and marathon#####
This repo contains ansible scripts to install and uninstall mesos on bare metal hardware.

Please read this readme file in its entirety before attempting to use it on your own cluster.

See [Apache Mesos](http://mesos.apache.org/) for comprehensive documentation on what it does and how it is configured.

A copy of ansible needs to be [installed](http://docs.ansible.com/ansible/intro_installation.html) on your workstation. If you are a Mac user then
```
brew install ansible
```

will install ansible.

The ansible scripts and files were created for a mesos system consisting of 5 physical hosts in total, owned by the author.

The file `/cluster` shows the hosts assigned these role types. 

There is one role type which is non standard, `builder`. This is the host which is used to compile and build the mesos files from the Apache source. The files are then distributed to the other hosts in the cluster.

If multiple zookeeper nodes are required then an odd number needs to be used and the nodes need to be added accordingly to `/cluster`. Against each node a *myid* variable needs to be assigned. For simplicity the numbers should be sequential starting with 1 e.g.

If one zookeeper node is being used then the zookeeper section needs to show
```
[zookeeper]
172.16.2.60 myid=1
```

If three zookeeper nodes are required then the zookeeper section needs to show
```
[zookeeper]
172.16.2.60 myid=1
172.16.2.61 myid=2
172.16.2.62 myid=3
```

If the *myid* variables are not correctly specified in the `/cluster` file then zookeeper will not work. 

The download locations and versions of the source packages used are in `/group_vars/all`

There are other role types which are master, zookeeper, marathon and agent. Each role type is configured by the ansible scripts.

The ansible scripts configure docker as the primary containerizer. If the mesos containerizer is only required then modify

`/mesos_agent/templates/mesos_agent_script.conf`

and change `containerizers=docker,mesos` to `containerizers=mesos` for the mesos container only.

The **IP addresses for the hosts must be changed to match your system**. The host distribution in the `/cluster` file can also be changed. In a production system it is recommended that there are a minimum of 3 zookeeper hosts, 3 masters and 3 marathon hosts. The author has used 1 server hosting zookeeper, master and marathon role types and used the remaining four as agents. The builder, as mentioned earlier, is only used during the installation of the cluster and after the installation can be treated as any other role type depending on the configuration in `/cluster` e.g.

```
[master]
172.16.2.60
172.16.2.61
172.16.2.62

[zookeeper]
172.16.2.60 myid=1
172.16.2.61 myid=2
172.16.2.62 myid=3

[marathon]
172.16.2.60
172.16.2.61
172.16.2.62


[agent]
172.16.2.63
172.16.2.64

[builder]
172.16.2.64
```

The master nodes are 172.16.2.[60-62] 
The zookeeper nodes are 172.16.2.[60-62] with sequential *myid* values
The agent nodes are 172.16.2.[63-64]
The builder node is 172.16.2.64 which is used to build mesos.

The installation scripts have been tested with Ubuntu 14.04.4.  The scripts will need modifying if people want to use them with a different operating system.

The versions of mesos, zookeeper and marathon used by the scripts can be changed in `/group_vars/all`

###Prerequisites for script use###

Ansible prefers passwordless SSH. You will need to follow the instructions on [THEGEEKSTUFF](http://www.thegeekstuff.com/2008/11/3-steps-to-perform-ssh-login-without-password-using-ssh-keygen-ssh-copy-id/) to configure passwordless SSH. The version of ansible used was 2.0.1.

In the file `/groups_vars/all` there is a variable `username`. This needs to contain the *username* of the account you have setup in ubuntu. In `/group_vars/all` this *username* is set to ajazam. **PLEASE CHANGE THIS**.

###Script usage###
You need to clone the entire repo onto your workstation. The ansible scripts were written on an Apple Mac system and has been throughly tested there. Note the authors system is not a production system. The scripts should work on any linux system, but they haven't been tested.

To run the install script you need to run the following on your workstation
```
ansible-playbook -i cluster install.yml --ask-become-pass
```
You will be prompted for a password for your *username*.

To remove all the software and data from the cluster run the following on your workstation

```
ansible-playbook -i cluster uninstall.yml --ask-become-pass

```
You will be prompted for a password for your *username*.

To access the master HTTP web page you need use the following URL http://172.16.2.60:5050

To access the marathon HTTP web page you need to use the following URL http://172.16.2.60:8080

Curl can be used to post jobs to marathon. To send a test job to marathon type the following on your workstation

```
curl -X POST http://172.16.2.60:8080/v2/apps -d @sleep.json -H "Content-type: application/json"

```

This will create one instance of the job described inside sleep.json. 

sleep2.json will create two instances of the job described in sleep2.json.

We assume there is one marathon instance at 172.16.2.60. If you are using multiple marathon instances then you must access the web page on one of your marathon instances. You will automatically be redirected to the leader marathon instance. Use this redirected IP in the above command to post a job to marathon.

The ansible script configures the authentication to allow the use of persistent volumes. The persistent volumes can be configured easily for your jobs via marathon. You must use marathon 1.0.0.RC1 and above for persistent volumes. Note: the persistent volumes are created with root permissions. If you use a docker container where a directory from inside the docker image is mapped to a persistent volume then any user referenced inside the docker image must be the root user. This happens with the jenkins docker image. You need to build the jenkins image on all your agents running docker, and ensure that jenkins is running as the root user.

See [stack overflow](http://stackoverflow.com/questions/36403082/permission-errors-running-jenkins-inside-docker-using-persistent-volumes-with-ma/36438789#36438789) for more details.


##Miscellaneous scripts and commands used during development of the mesos installation script##

To update all hosts

```
ansible-playbook -i cluster update_cluster.yml --ask-become-pass
```

To build jenkins image from dockerfile run following in directory containing jenkins dockerfile
```
sudo docker build --build-arg user=root --build-arg group=root --build-arg uid=0 --build-arg gid=0 .
```

To remove containers
```
sudo docker ps -q -a | xargs sudo docker rm
```

To remove images
```
sudo docker images -q | xargs sudo docker rmi
```

To run docker without sudo for ubuntu *username* `ajazam`
```
sudo usermod -aG docker ajazam
```