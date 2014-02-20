#!/bin/sh
sudo docker run -p 2100:22 -d -i -t -v /home/vagrant/rpush:/mnt/rpush:ro rpush:latest
