# Starting Jenkins on Docker

## Commands

```js
#Mapping just home
docker run -d -u root -p 8080:8080 --name jenkins -v /var/jenkins:/var/jenkins_home jenkins/jenkins:latest 

#Mapping home and tmp
docker run -d -u root -p 8080:8080 --name jenkins -v /var/jenkins:/var/jenkins_home -v /tmp/:/tmp/ jenkins/jenkins:latest 

#Stop container
docker stop jenkins

#Restart container
docker restart jenkins
docker start jenkins

#Execute a command on a container
docker run jenkins

#List containers
docker container ls --all

#Remove a container
docker rm --force jenkins

#Enter to a container
docker ps
docker exec -it jenkins /bin/bash
```

## TAR file commands

```js
#Create a jenkins bkp file
tar -cvzf /tmp/jenkins/bkps/backup_2021_09_09_06_48.tar.gz /var/jenkins

#List content of a file
tar -tvzf backup_2021_09_07_12_09_15_259.tar.gz 

#Extract specific files to current folder
mkdir /tmp/jenkins/bkps/files
cd /tmp/jenkins/bkps/files
tar -xzf /tmp/jenkins/bkps/backup_2021_09_07_12_09_15_259.tar.gz jobs secrets credentials.xml 

#Replace file on current installation
cp -r /tmp/jenkins/bkps/files /var/jenkins

#Restart the Jenkins server
http://localhost:8080/restart
```

Other commands

```js
#Extract all files with specific extension
tar --wildcards '*.py' -xvf webroot.tar.xz

```

## Set up Jenkins on Docker for run helloworld

```js
docker exec -it jenkins /bin/bash
apt update
apt install nodejs
apt install npm
```

