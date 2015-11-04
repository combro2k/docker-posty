#!/bin/bash

if ! docker ps -a --filter="name=mariadb" --format='{{.Names}}' | grep -i mariadb; then
    docker run -d -e MYSQL_ROOT_PASSWORD=test --name  mariadb -v /tmp/mariadb:/var/lib/mysql mariadb:latest
else
    docker start mariadb
fi 2>&1 > /dev/null

if docker ps -a --filter="name=posty" --format='{{.Names}}' | grep -i posty; then
	docker rm posty
fi 2>&1 > /dev/null

docker run \
    -ti \
    --rm \
    --name posty \
    --link mariadb:mysql \
    -e POSTY_USER=root \
    -e POSTY_PASSWORD=test \
    -p 9292:9292 \
    combro2k/posty_api:latest ${@}

docker stop mariadb
