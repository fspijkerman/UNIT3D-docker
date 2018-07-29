# UNIT3D-docker

## Requirements

* Docker
* docker-compose

## Install

### DockerCE

```
$ curl https://get.docker.com | sudo bash
```

### docker-compose

```
$ sudo curl -L https://github.com/docker/compose/releases/download/1.22.0/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
$ chmod +x /usr/local/bin/docker-compose
```

### Setup your .env file

```
$ cp .env-sample .env
$ vi .env
```

### Build docker images

```
$ docker-compose build
```

### Using the UNIT3D Stack

Starting
```
$ docker-compose up
```

Stopping
```
$ docker-compose down
```

Start and detach to background
```
$ docker-compose up -d
```

Watching the logs 
```
$ docker-compose logs -f
```

Access in the container
``` 
$ docker-compose exec <namecontainer> sh
```

Status/List of running containers
```
$ docker-compose ps
```
