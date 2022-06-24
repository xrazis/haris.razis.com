---
title: "resolved.conf"
summary: Unresolvable host workaround
date: 2022-06-23
tags: ["Linux", "systemd", "Networking"]
draft: false
---

# Introduction

I encountered a weird issue the other day at work where I could not resolve a specific dev server on my laptop. Despite
being logged to the company's VPN and being able to resolve all the other servers, this specific one stubbornly
refused. Going through the debugging process of a complex network was not an option, so `resolved.conf` came to the
rescue.

# Network Name Resolution configuration files

The file `resolved.conf` is responsible for local DNS and LLNMR (Link-Local Multicast Name Resolution) name resolution.
The main file can be found under `/etc/systemd` and its entries override any defaults. The following configuration was
needed for the server to resolve.

1. `DNS` - Define the IPv4/IPv6 entry (or entries) to use as a system DNS servers.
2. `Domains` - Domains we want to process using the predefined DNS servers. They are processed in the order they are
   listed, until a match is found.

```conf
DNS=195.47.208.14
Domains=opap.local open.local
```

After saving the file with the new entry reload the services as such:

```zsh
~
➜ sudo systemctl daemon-reload
  sudo systemctl restart systemd-networkd
  sudo systemctl restart systemd-resolved
```

And check that the server now resolves:

```zsh
~
➜ ping tzokerdev.opap.gr -c 4
PING pamdev05.opap.local (10.126.2.45) 56(84) bytes of data.
64 bytes from 10.126.2.45 (10.126.2.45): icmp_seq=1 ttl=63 time=32.9 ms
64 bytes from 10.126.2.45 (10.126.2.45): icmp_seq=2 ttl=63 time=30.5 ms
64 bytes from 10.126.2.45 (10.126.2.45): icmp_seq=3 ttl=63 time=29.5 ms
64 bytes from 10.126.2.45 (10.126.2.45): icmp_seq=4 ttl=63 time=32.8 ms

--- pamdev05.opap.local ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3004ms
rtt min/avg/max/mdev = 29.503/31.433/32.931/1.469 ms
```
