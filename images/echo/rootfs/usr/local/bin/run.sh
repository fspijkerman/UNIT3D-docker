#!/bin/sh

echo "Waiting to start laravel-echo-server"
while [ ! -f /usr/src/app/laravel-echo-server.json ] ; do
  sleep 2
done

echo "Starting laravel-echo-server!"
exec laravel-echo-server $*
