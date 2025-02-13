---
title: My struggles with selfhosting
date: 2025-02-11
tags: [ Linux, Networking, System, Coolify ]
draft: true
---

# Introduction

It all starts pretty naively. You host your first website on something like GitHub or Cloudflare pages. Then you

# Plesk is a reminisce of the past

It was good enough, with a nice feature set, good extensibility with addons, and a low price. You would even get it for
free when renting a server at most providers. BUT, they dismantled the free tier and kept increasing prices without
adding any real value to the product. On top of that, most of the 'must have' extensions are premium, which further
raises the price.

The price increases are ridiculous and not justified. They will keep jacking them year after year to satisfy investors.

# Selfhosting email is a pain in the @ss

I learned half a dozen of acronyms I had to implement. I verified my domains with the top providers. I made sure my IP
is crystal clear and has a good reputation. I checked and verified that all the outgoing emails contained no suspicious
activity. I even considered sacrificing humans to the blacklist gods.

No matter what I did, inevitably, my emails would be marked as spam and get bounced. To add the cherry on the cake, you
also have to manage the incoming spam. Set up spamassassin, start using Spamhaus blocklists, manually block IP
addresses...

The amount of work required to keep this running is something I no longer have the mental capacity to do. The internet
was designed as many independent nodes, and you should be able to run your own email as it is a federated service. But,
apparently, we are in the age of walled garden services that all require subscriptions.

Well, if I am going to throw in the towel on selfhosting my email, to what service should I turn to?

# My upcoming utopia

After accepting my situation, I began [kagi](https://kagi.com/)ng for new server panels and email providers.

For the server panel I was looking for an actively maintained open source package with a strong community. Not because
it was free. After all, I do believe that OS software should be [free as in weekend](https://freeasinweekend.org/). But
//TODO. I stumbled upon [coolify,](https://coolify.io) and it has a dedicated developer on the project, great
community, and is a stellar product! I could not be happier. After quickly bootstraping a server and testing the main
functionality, I decided it was the one!

As for the email, I did not want to choose a provider like Google. Nor did I want a freemium offering like Zoho. I
wanted 