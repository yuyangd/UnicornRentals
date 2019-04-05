# AWS Game Day - Unicorn Rentals

duyuyang/unicorn
duyuyang/nginx

userdata

```bash
#!/bin/bash
sleep 30
yum -y install wget
wget https://s3.amazonaws.com/ee-assets-prod-us-east-1/modules/gd2015-loadgen/v0.1/server
chmod +x server
./server
# Reboot if the server crashes
shutdown -h now
```

new user data

```bash
#!/bin/bash
docker volume create --name=cache
wget https://raw.githubusercontent.com/yuyangd/UnicornRentals/master/docker-compose.yml -O /tmp/docker-compose.yml
cd /tmp
docker-compose up -d --scale web=2
```