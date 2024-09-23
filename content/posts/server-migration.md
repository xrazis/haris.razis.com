---
title: Server Migration
summary: Migrating a Plesk server with multiple production environments.
date: 2024-09-23
tags: [ "System", "Linux", "Networking", "Plesk" ]
draft: false
---

# Introduction

I have been maintaining a managed Plesk server on a Greek hosting provider for the past few years. It contains a handful
of production websites and their respective mail servers. While it was okayish for basic hosting needs, the demands
quickly outgrew it with limitations starting to appear on the infrastructure, supported technologies, and services.

After a little market research, I decided that the way forward would be Digital Ocean, as they provide solid cloud
infrastructure with a plethora of tools. I also decided to keep Plesk as the server
management platform. It will be adequate for the low needs of basic Node.js sites and small eshops, with the
added benefit of an embedded mail server, security features, automations, and backups.

# Digital Ocean and Plesk

Digital Ocean features droplets, which are servers, standalone or part of a larger infrastructure—essentially
Linux-based virtual machines on top of virtualized hardware. Digital Ocean's marketplace offers ready-to-deploy
droplets, and the one we are interested in is [Plesk](https://marketplace.digitalocean.com/apps/plesk). It comes on top
of Ubuntu and bundles with common server software like Apache, Nginx, Git, and many more. What you don't find out of the
box can probably be installed as an extension to Plesk.

Setting up is trivial, you follow the onscreen instructions, and you are set to go in no time. The Plesk panel login URL
is going to be your droplet's public IP address. I scaled the droplet to 2vCPU, 4GB RAM; it should be more than adequate
for the Plesk instance to handle the relatively small load of my websites.

From the Digital Ocean panel you can set up monitoring for resources and uptime, manage your domains, increase allocated
resources, span new droplets, configure a firewall, or split the traffic to many droplets with a load balancer. The list
just goes on. I'm really fond of the way they structured it.

# Website and email Migration

### Node.js and Hugo

Migrating websites built on Node.js and Hugo is fairly easy:

1. Set up the corresponding webspaces.
2. Set up automatic Git deployment.
   1. For Node.js sites set through the plesk extension. Make sure there is no leftover index.html in the document root
      or else you are always going to be served the Plesk default page!
   2. For static sites like Hugo point to the correct document root (`/httpdocs/public`) through the Hosting settings.
3. Change nameservers and point the domain to the DO nameservers. Be sure to configure the DigitalOcean DNS extension as
   well.
4. Once the nameserver change propagates, install the new SSL certificates. It appears that `.com` domains propagates
   quite fast, whereas `.gr` domains take a while longer.

### WordPress

WordPress sites can be migrated by either a dedicated plugin or manually by moving the DB and files. I chose to move
them by hand.

1. Make a new instance of WordPress. Give it the same name as the website you are bringing over.
2. Move files from the old server. If you have ssh access, zip and then use rsync to bring them over. Once you replace
   the old files, remember to change permissions. Use the system user for that specific webspace, and execute
   `chown -R <user>:<group> httpdocs`. You can see what group the previous installation used, but it is probably going
   to be `psserv`.
3. Export and import the DB. Once that's done change the DB credentials from `wp-config.php`
4. You should now be able to access the WP admin panel. In my specific case it was an eshop on top of Woo,
   so I had to clear relevant DB caches and run a thumbnail regeneration.

### Email

Migrating emails from the old server can be done with Plesk's mail importing tool. First, create the mailbox in the new
server and then follow the onscreen instructions. I found that it also moves the folder structure besides the emails.
I exported and reimported the email filters separately.

# Plesk configuration

### Change Plesk URL

Up until now I have been using the randomly generated `plesk.page` URL to access my instance without an SSL warning. I
decided to change it to something more appropriate that would be easy to remember. I used a subdomain that was not used
and also resolves to the server IP—I added an A record to DO DNS records that pointed to the droplet IP. That needs to
be changed in two places:

1. `/Tools & Settings/Customizing Plesk URL`
2. `/Tools & Settings/Server Settings/Full Hostname`

Be sure to issue a valid certificate for your server subdomain/domain. Keep a reference to this section. We are going to
discuss a nerve-racking misconfiguration I encountered later.

### Back up

There are two options for backing up Plesk configuration, sites, email, and databases:

1. On site—the droplet disk
2. Remote—an external server

I have configured both of them. Keeping the backups only on the disk of the droplet is not a good idea. Syncing backups
to more than one external server is the way to go with critical data. If things go wrong, you will be able to spin up
a new plesk instance much faster this way. There are many Plesk extensions that can sync with DO, Google Drive, and FTP
servers.

Plesk will first do a full backup and afterward do an incremental backup that only contains the data that has changed
since. This way, the following backups are less hard on CPU and disk.

# Problems

Would it be a true migration without problems? Once everything was transferred and the nameservers were switched, every
outgoing mail would get marked as spam from Google, Hotmail, Proton, etc. Some would even get bounced and not get
delivered at all. A little digging in the logs and I found the following bounce the server got from a forward rule I
have on an email account:

```bash
Sep 21 09:27:58 0EEA7827E9: to=<XXXX@hotmail.com>, relay=hotmail-com.olc.protection.outlook.com[52.101.194.5]:25,
delay=1, delays=0.01/0.01/0.88/0.11, dsn=5.7.1, status=bounced (host hotmail-com.olc.protection.outlook.com
[52.101.194.5] said: 550 5.7.1 Service unavailable, Client host [XXX.XXX.XXX.XXX] blocked using Spamhaus. 
To request removal from this list see https://www.spamhaus.org/query/ip/XXX.XXX.XXX.XXX (AS3130). 
[Name=Protocol Filter Agent][AGT=PFA][MxId=11B9A53DC314A6C4] 
[CH3PEPF0000000F.namprd04.prod.outlook.com 2024-09-21T09:27:58.008Z 08DCD29EEC0C7774] (in reply to MAIL FROM command))
```

So the server is officially on a spam list. Upon checking the incoming mail headers, I also discovered the following:

```bash
Received: from goofy-lewin.XXX-XXX-XXX-XXX.plesk.page...
Received: from webmail.mydomain.gr (localhost.localdomain [IPv6:::1]) by goofy-lewin.XXX-XXX-XXX-XXX.plesk.page (Postfix) 
Received-Spf: pass (goofy-lewin.XXX-XXX-XXX-XXX.plesk.page: connection is authenticated)
```

I forgot to change the domain address from the temporary generated plesk.page to something I owned. The steps are
described in the section [Change Plesk URL](#change-plesk-url).
[Spamhaus describes this misconfiguration](https://www.spamhaus.org/faqs/combined-spam-sources-css/#misconfigured-plesk-hosts-in-css)
on their FAQ:

```md
The host name used in the SMTP greeting is the Plesk server host name specified in Tools & Settings > Server Settings.
Selecting this option may result in mail sent from some or all domains being marked as spam if the Plesk server host
name fails to resolve properly, or if the domain’s IP is different from the one to which the Plesk server host name
resolves.
```

So changing the Plesk URL should resolve all of these issues. I also went ahead and added the hostname in the postfix
template, as per
[Plesk instructions](https://support.plesk.com/hc/en-us/articles/12377559724567-How-to-change-the-hostname-and-SMTP-banner-in-Postfix-on-a-Plesk-server).
You also have to update the DNS templates from Plesk and sync the changes to Digital Ocean. The specific 'problematic'
record is the host txt record.

```bash
domain.com.		TXT 	v=spf1 +a +mx +a:goofy-lewin.XXX-XXX-XXX-XXX.plesk.page -all
```

After the aforementioned changes, everything was back to normal.
