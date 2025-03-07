---
title: My struggles with selfhosting
date: 2025-02-11
tags: [ Linux, Networking, System, Coolify ]
draft: true
---

# Here we go again

Half a year ago [I migrated my server](/posts/server-migration/). The tech stack was largely unchanged, but it was a
tedious process to bring everything over. For a while I was happy. For a very little while.

![](https://media1.tenor.com/m/cJRcMyUAiMcAAAAd/ah-shit-here-we-go-again-ah-shit.gif)

# Plesk is a reminisce of the past

Plesk was good enough, with a nice feature set ootb, good extensibility with addons, beginner-friendly, and a low price.
You would even get it for free when renting a server at some providers. Unfortunately, they dismantled the free tier and
kept increasing prices without adding any real value to the product. On top of that, most of the 'must have' extensions
are premium, which further raises the price.

The price increases are ridiculous and not justified. They will keep jacking them year after year to satisfy investors.
The literal definition of product enshittification. The parent company also bought cPanel a few years back, Plesk's main
competitor...

# Selfhosting email is a pain in the ass

I learned half a dozen of acronyms I had to implement. I verified my domains with the top providers. I made sure my IP
is crystal clear and has a good reputation. I checked and verified that all the outgoing emails contained no suspicious
activity. I even considered sacrificing humans to the blacklist gods.

No matter what I did, inevitably, my emails would be marked as spam and get bounced. An asshole neighbor on the VPS
provider that shares the same IP block? Someone that decided to mark my email as spam and fuck up my day? Unexplainable
blocking from larger providers? No matter the root cause, the result was the same. My emails were not delivered.

To add the cherry on the cake, you also have to manage the incoming spam. Set up spamassassin, start using Spamhaus
blocklists, manually block IP addresses...

> Fun fact: The term spam originates from a [monty python sketch](https://www.youtube.com/watch?v=anwy2MPT5RE). Also,
> [Gary Thuerk](https://www.computerworld.com/article/1569672/unsung-innovators-gary-thuerk-the-father-of-spam.html)
> sent The first spam email. The military scolded him for writing that email.

The amount of work required to keep this running is something I no longer have the mental capacity to do. The internet
was designed as many independent nodes, and you should be able to run your own email. After all, it is a federated
service. But apparently, we are in the age of walled garden services that all require subscriptions. This is
basically [email vs capitalism](https://www.youtube.com/watch?v=mrGfahzt-4Q).

Well, if I am going to throw in the towel on selfhosting my email, to what service provider should I turn to?

# My planned utopia

After accepting my situation, I began [kaging](https://kagi.com/) for new server panels and email providers.

For the server panel I was looking for an actively maintained open source project with a strong community. Not because
you can (probably) get it for free. After all, I do believe that OS software should
be [free as in weekend](https://freeasinweekend.org/), and that you should also donate to OS projects regularly. But
because I wanted to avoid [serverless horrors](https://serverlesshorrors.com/) and vendor lock in. I stumbled
upon [Coolify](https://coolify.io). It has two dedicated developers on the project, a great community, and is a stellar
product! I could not be happier.

As for the email, I did not want to choose a provider like Google. Nor did I want a freemium offering like Zoho. I
wanted something private and encrypted. I rounded it down to [Tuta](https://tuta.com/). Although not as mature as
Proton (another popular encrypted email), I liked it more.

I am not hallucinating that a private and encrypted email provider will suddenly protect my emails from big tech and
surveillance capitalism. I already know
that [Google has most of my mail because it has all of yours](https://mako.cc/copyrighteous/google-has-most-of-my-email-because-it-has-all-of-yours).
I really did not want to give my money to big tech, so instead I picked a smaller company with a vision for a better
web. Let's hope they stay true to their mission.

# Setting up Coolify

//TODO How does coolify work

Everything inside Coolify runs as a Docker container, even the panel itself and all the necessary components. The cool
thing with coolify is that you are not locked in an ecosystem (e.x. Vercel). 

//TODO How straightforward is bootstrapping

### WordPress migrating

I do not like WordPress. I actually despise it. Unfortunately, I have inherited two WP websites. I exported the contents
with a plugin and reimported everything on the new instance.

Coolify has a WP service that you can quickly deploy within a few minutes. It also provides backups for the database to
S3 compatible storage (more on that later).

### Mailgun

### Axiom

### S3 backups

I guess we are now all calling them S3 because AWS pioneered the space? Whatever the case may be, I am already
using Cloudflare R2 for my CDN as it has a generous free plan. I created a new bucket for the backups and enabled them
for the panel and the various databases. Unfortunately, there are no more S3 backup options at the moment. One nice
addition would be a docker volume S3 backup.

### Troubleshooting

It was mostly pain-free, but:

- The panel and the apps crashed because the server ran out of memory. That was due to a high spike of traffic to one of
  the web apps. Rebooting and upscalling the droplet solved the issue.
-

# Closing thoughts
