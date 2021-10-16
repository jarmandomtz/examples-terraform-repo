
# Application dockerization

**Docker Installation**
Documentation for docker installation [here](./DockerInstallationOnUbuntu.md)

Reference,
- official AWS Docker image. You can read more about this at http://amzn.to/2jnmklF.

Steps
- Pull alphine image from docker registry
- Run a container
- Search the image to be used on cli or web (https://hub.docker.com/_/node/.)
- Create a Dockerfile on helloworld project, on "dockerized" branch
- Build the image
- Run a docker from the created image
- Validate in logs container is running and using curl
- Kill the container

```js
%> docker pull alpine 

%> docker images
REPOSITORY        TAG            IMAGE ID       CREATED         SIZE
alpine            latest         14119a10abf4   7 weeks ago     5.6MB

%> docker run alpine echo "Hello World"
Hello World

%> docker search --filter=is-official=true node
NAME            DESCRIPTION                                     STARS     OFFICIAL   AUTOMATED
node            Node.js is a JavaScript-based platform for s…   10635     [OK]       
mongo-express   Web-based MongoDB admin interface, written w…   1066      [OK] 

helloworld %> cat Dockerfile
FROM node:carbon
RUN mkdir -p /usr/local/helloworld/
COPY helloworld.js package.json /usr/local/helloworld/
WORKDIR /usr/local/helloworld/
RUN npm install --production
EXPOSE 3000
ENTRYPOINT [ "node", "helloworld.js" ]


# Build the image
# -t           means name/tag of the created image
#  .           menas path of the Dockerfile
helloworld %> docker build -t helloworld .
Sending build context to Docker daemon  24.35MB
Step 1/7 : FROM node:carbon
carbon: Pulling from library/node
...
Status: Downloaded newer image for node:carbon
 ---> 8eeadf3757f4
Step 2/7 : RUN mkdir -p /usr/local/helloworld/
 ---> Running in 2d96c93361f0
Removing intermediate container 2d96c93361f0
 ---> 1549903d6232
Step 3/7 : COPY helloworld.js package.json /usr/local/helloworld/
 ---> ec0446b7c6c3
Step 4/7 : WORKDIR /usr/local/helloworld/
 ---> Running in 2fee9729d0a7
Removing intermediate container 2fee9729d0a7
 ---> ebfeb59f223b
Step 5/7 : RUN npm install --production
 ---> Running in 6f4683a41c0c
audited 197 packages in 8.385s
found 1 moderate severity vulnerability
  run `npm audit fix` to fix them, or `npm audit` for details
Removing intermediate container 6f4683a41c0c
 ---> 4d83cba513d8
Step 6/7 : EXPOSE 3000
 ---> Running in 62a241a491b1
Removing intermediate container 62a241a491b1
 ---> cdaa66eb1cff
Step 7/7 : ENTRYPOINT [ "node", "helloworld.js" ]
 ---> Running in 3df5ea78e08a
Removing intermediate container 3df5ea78e08a
 ---> 3d76dd7532f8
Successfully built 3d76dd7532f8
Successfully tagged helloworld:latest

helloworld%> docker images
REPOSITORY        TAG            IMAGE ID       CREATED              SIZE
helloworld        latest         3d76dd7532f8   About a minute ago   912MB
node              carbon         8eeadf3757f4   21 months ago        901MB

# Run a container
$ -p         meaning map the exposed port of the container to a port on the host
%> docker run -p 3000:3000 -d helloworld
d0fd4eafc25fde18fe85724c238e724a4145e4d664c66947308e9d21862d407d

%> docker ps
CONTAINER ID   IMAGE        COMMAND                CREATED          STATUS          PORTS                                       NAMES
d0fd4eafc25f   helloworld   "node helloworld.js"   24 seconds ago   Up 22 seconds   0.0.0.0:3000->3000/tcp, :::3000->3000/tcp   elastic_shockley

%> docker logs d0fd4eafc25fde18fe85724c238e724a4145e4d664c66947308e9d21862d407d
Server running

%> curl localhost:3000
Hello World

%> docker kill d0fd4eafc25f

%> docker ps --all
CONTAINER ID   IMAGE                    COMMAND                  CREATED         STATUS                        PORTS     NAMES
d0fd4eafc25f   helloworld               "node helloworld.js"     8 minutes ago   Exited (137) 10 seconds ago             elastic_shockley
```
## Cleaning environment
Steps,
- Stop all running containers
- Remove all stoped containers, networks not user, dangling images, build cache

```js
%> docker stop $(docker ps -a -q)
d0fd4eafc25f
c406f7a763f2

%> docker system prune
WARNING! This will remove:
  - all stopped containers
  - all networks not used by at least one container
  - all dangling images
  - all dangling build cache

Are you sure you want to continue? [y/N] y
Deleted Containers:
d0fd4eafc25fde18fe85724c238e724a4145e4d664c66947308e9d21862d407d
c406f7a763f2a6f5d5ab577588ead300ece33940dc06735abdb968d3109c5553

Total reclaimed space: 937.2MB

%> docker ps --all
CONTAINER ID   IMAGE     COMMAND   CREATED   STATUS    PORTS     NAMES
%>

```
