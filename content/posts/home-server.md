---
title: "Home Server"
summary: Repurposing an old computer
date: 2023-03-31
tags: [ "Linux", "System" ]
draft: true
---

# Introduction

My old desktop was lying arround so i decided to flash it with Ubuntu and repurpose it as a Home Server. I tried to keep
all the services inside Docker and manage them with `docker compose` to make deployment, migrating, and updating
simpler.

# Docker Compose Services

- **tailscale**, to remotely connect to the homelab.
- **ngnix-proxy**, to proxy all the requests to the services running in the containers. A neat thing is you can use a
  LAN hostname for all the services.
- **pihole**, as an adblocker and a DNS server.
- **unifi**, for controlling the wifi clients and the AP.
- **home assistant**, for home automation, controlling the water heater, lights, door sensors, etc.
- **fresh rss**, RSS aggregator in order to have all the news in one place.

### docker-compose.yaml

```Dockerfile
version: '3'

services:

  nginx-proxy:
    image: nginxproxy/nginx-proxy:latest
    container_name: nginx_proxy
    ports:
      - '80:80'
    environment:
      DEFAULT_HOST: pihole.lan
    volumes:
      - '/var/run/docker.sock:/tmp/docker.sock'
    restart: always

  pihole:
    image: pihole/pihole:latest
    container_name: pihole
    ports:
      - '53:53/tcp'
      - '53:53/udp'
      - '67:67/udp'
      - '8053:80/tcp'
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    cap_add:
      - NET_ADMIN
    environment:
      FTLCONF_LOCAL_IPV4: 192.168.1.5
      PROXY_LOCATION: pihole
      VIRTUAL_HOST: pihole.lan
      VIRTUAL_PORT: 80
    extra_hosts:
      # Resolve to nothing domains (terminate connection)
      - 'nw2master.bioware.com nwn2.master.gamespy.com:0.0.0.0'
      # LAN hostnames for other docker containers using nginx-proxy
      - '.lan:192.168.1.5'
      - 'pihole pihole.lan:192.168.1.5'
      - 'unifi unifi.lan:192.168.1.5'

  mongo:
    image: mongo:3.6
    container_name: unifi_mongo
    networks:
      - unifi
    restart: always
    volumes:
      - db:/data/db
      - dbcfg:/data/configdb

  controller:
    image: jacobalberty/unifi:latest
    container_name: unifi_controller
    depends_on:
      - mongo
    init: true
    networks:
      - unifi
    restart: always
    volumes:
      - dir:/unifi
      - data:/unifi/data
      - log:/unifi/log
      - cert:/unifi/cert
      - init:/unifi/init.d
      - run:/var/run/unifi
      # Mount local folder for backups and autobackups
      - ./backup:/unifi/data/backup
    user: unifi
    sysctls:
      net.ipv4.ip_unprivileged_port_start: 0
    environment:
      DB_URI: mongodb://mongo/unifi
      STATDB_URI: mongodb://mongo/unifi_stat
      DB_NAME: unifi
      FTLCONF_LOCAL_IPV4: 192.168.1.5
      PROXY_LOCATION: unifi
      VIRTUAL_HOST: unifi.lan
      VIRTUAL_PORT: 8443
    ports:
      - '3478:3478/udp' # STUN
      - '6789:6789/tcp' # Speed test
      - '8080:8080/tcp' # Device/ controller comm.
      - '8443:8443/tcp' # Controller GUI/API as seen in a web browser
      - '8880:8880/tcp' # HTTP portal redirection
      - '8843:8843/tcp' # HTTPS portal redirection
      - '10001:10001/udp' # AP discovery

  logs:
    image: bash
    container_name: unifi_logs
    depends_on:
      - controller
    command: bash -c 'tail -F /unifi/log/*.log'
    restart: always
    volumes:
      - log:/unifi/log

volumes:
  db:
  dbcfg:
  data:
  log:
  cert:
  init:
  dir:
  run:

networks:
  unifi:
```

# Problems

### resolved.conf
