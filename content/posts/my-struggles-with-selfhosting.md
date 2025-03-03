---
title: My struggles with selfhosting
date: 2025-02-11
tags: [ Linux, Networking, System, Coolify ]
draft: true
---

# Introduction

It all starts pretty naively. You host your first website on something like GitHub or Cloudflare pages. You then do a
bit of freelancing and the needs //TODO

# Plesk is a reminisce of the past

It was good enough, with a nice feature set, good extensibility with addons, beginner-friendly, and a low price. You
would even get it for free when renting a server at some providers. Unfortunately, they dismantled the free tier and
kept increasing prices without adding any real value to the product. On top of that, most of the 'must have' extensions
are premium, which further raises the price.

The price increases are ridiculous and not justified. They will keep jacking them year after year to satisfy investors.
The literal definition of product enshittification.

# Selfhosting email is a pain in the ass

I learned half a dozen of acronyms I had to implement. I verified my domains with the top providers. I made sure my IP
is crystal clear and has a good reputation. I checked and verified that all the outgoing emails contained no suspicious
activity. I even considered sacrificing humans to the blacklist gods.

No matter what I did, inevitably, my emails would be marked as spam and get bounced. An asshole neighbor on the VPS
provider that shares the same IP block? Someone that decided to mark my email as spam and fuck up my day? Unexplainable
blocking from larger providers? No matter the root cause, the result was the same. My emails were not delivered.

To add the cherry on the cake, you also have to manage the incoming spam. Set up spamassassin, start using Spamhaus
blocklists, manually block IP addresses...

The amount of work required to keep this running is something I no longer have the mental capacity to do. The internet
was designed as many independent nodes, and you should be able to run your own email. After all, it is a federated
service. But apparently, we are in the age of walled garden services that all require subscriptions. [Email vs
Capitalism](https://www.youtube.com/watch?v=mrGfahzt-4Q).

Well, if I am going to throw in the towel on selfhosting my email, to what service provider should I turn to?

# My upcoming utopia

After accepting my situation, I began [kagi](https://kagi.com/)ng for new server panels and email providers.

For the server panel I was looking for an actively maintained open source project with a strong community. Not because
you can (probably) get it for free. After all, I do believe that OS software should
be [free as in weekend](https://freeasinweekend.org/), and you should donate to OS projects regularly. I stumbled
upon [Coolify](https://coolify.io). It has two dedicated developers on the project, a great community, and is a stellar
product! I could not be happier. After quickly bootstrapping a server and testing it out, I decided it was the one.

As for the email, I did not want to choose a provider like Google. Nor did I want a freemium offering like Zoho. I
wanted something private and encrypted with a vision for a better web. I rounded it down to [Tuta](https://tuta.com/).
Although not as mature as Proton (another popular encrypted email), their feature set and price fitted me better.

# Setting up Coolify

//TODO How does coolify work

//TODO How straightforward is bootstrapping

### WordPress migrating
    
I do not like WordPress. I actually despise it. 

### Mailgun

### Axiom

### S3 backups

I guess we are now all calling them S3 because AWS pioneered the space? Whatever the case may be, I am already
using Cloudflare R2 for my CDN as it has a generous free plan. I created a new bucket for the backups and enabled them
for the panel and the various databases. Unfortunately, there are no more S3 backup options at the moment. One nice
addition would be a docker volume S3 backup.

### Troubleshooting

# Closing thoughts

Selfhosting email 