---
title: Debugging Unifi connections
date: 2022-07-08
tags: [ Networking ]
draft: false
---

# Introduction
Having SSH access to the server you are battling with is an invaluable tool - no matter how feature-rich the console may be. In the few past days, we (my father and I) faced connectivity issues on a corporate network where a specific client (a POS device) would not stay attached to the nearest access point but instead hop to an AP further away. That caused connectivity problems with slow/failed transactions. It finally proved to be a miss-configuration issue (as it always is) but had we had proper logging, we could have resolved the issue much sooner.

# UniFi OS
The majority of hardware we use is from Ubiquity, with many different APs of various generations and a UDM PRO tying them all down. Unfortunately, Ubiquity's documentation is sparse, so the information seen in this post was collected from blogs and community forums.

The first step is to enable SSH access to the UDM through the settings and set a password. Then SSH  `root@192.168.1.1`  and enter the password you've just set. UniFi OS is based on [Buildroot](https://github.com/buildroot/buildroot) with some basic Linux commands (see those with `help`) and some UniFi-specific commands.

For some weird reason, UI decided we can't have docs for the CLI so we have to do some digging ourselves. As mentioned on the community forum we can find the commands defined in the file `syswrapper.sh`. Edit that file with `vi`:

```bash
vi `which syswrapper.sh`
```

Then search for `case $cmd in` in the file. You can search in vi by hitting `/` and typing the search term. Don't forget you can exit the file with `:q!`, which quits without saving. There is a [thread](https://www.reddit.com/r/Ubiquiti/comments/k2g8sk/some_useful_udmudmp_ssh_commands/) on Reddit and a [repository](https://github.com/TobyAnscombe/udm-setup) on GitHub that documents some of these commands. The following is a snippet from that file.

```bash
case $cmd in                                                                                                                    
set-tmp-ip)                                                                                                        
        exit_if_fake $cmd $*                                                                                                    
        ;;                                                                                                   
set-adopt)                                                                                                                      
        # set-adopt <url> <authkey>                                                                                             
        mca-ctrl -t connect -s "$1" -k "$2"                                                                                     
        ;;                                                                                                           
set-channel)                                                                                                       
        # set-channel <radio> <channel>                                                                              
        # FIXME: dual radio                                                                                                     
        for ath in `ls /proc/sys/net/*/%parent | cut -d '/' -f 5`; do                                                           
                iwconfig $ath channel $1                                                                                        
        done                                                                                                                    
        ;;                                                                                                                      
# ...                                                  
```

# Extracting logs
We are going to extract log files from two locations:

1.  `/var/log/messages` - error logs.
```bash
# Save the errors to a file
cat /var/log/messages > messages.log
# Then transfer the file to your machine
scp messages.log <user>@<device-name>:<path/to/transfer/to>
``` 

2. `/data/unifi-core/logs` - a directory that contains various UniFi OS logs.
```bash
# Archive the whole dir 
tar -zcvf unifi-core-logs.tar.gz /data/unifi-core/logs/
# Then transfer the file to your machine
scp messages.log <user>@<device-name>:<path/to/transfer/to>
``` 

From here on, you are going into a rabbit hole. May your soul find peace because reading these logs drove me crazy.

### Attributions
- [UniFi CLI / SSH commands list](https://community.ui.com/questions/Unifi-CLI-SSH-commands-list/e950d4c5-bf91-4f30-8d07-99103899328b#answer/03604df2-3dd1-4940-bffd-ddff72cae282)
- [All UniFi SSH Commands that You Want to Know](https://lazyadmin.nl/home-network/unifi-ssh-commands/)
- [How To SSH Into Your UniFi Dream Machine](https://evanmccann.net/blog/2020/5/udm-ssh)
- [UniFi - How to View Log Files](https://help.ui.com/hc/en-us/articles/204959834-UniFi-How-to-View-Log-Files)
- [UniFi - Getting Support Files and Logs](https://help.ui.com/hc/en-us/articles/360049956374-UniFi-UDM-Dream-Machine-Support-File-and-Logs)
