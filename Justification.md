# A quiet, efficient, robust and future-proof home-server, optionally headless.

### [What is it? And Why?](https://github.com/zilexa/Homeserver#what-is-it)
### [Why self-build?](https://github.com/zilexa/Homeserver#why-self-build-just-buy-a-synology-or-qnap)
### [What are the benefits of your setup files?](https://github.com/zilexa/Homeserver#what-are-the-benefits-of-adopting-your-setup-and-config-fully-or-partially)
### [Can I use the server as PC or workstation?](https://github.com/zilexa/Homeserver#can-i-use-the-server-as-pc-or-workstation-but-i-have-never-used-ubuntu)

## What is it?
An always-on PC like device that you can place near your router or even use as your Desktop/workstation. Giving you access to your data, providing you with a higher level of privacy and security and allowing you to be flexible with all online services you might use. 
Also see the [Features](https://github.com/zilexa/Homeserver#features) you get by simply following this guide. 

Why?
1. Be in control of your own precious data, think archived family photos and videos but also new photos from your next vacation. 
2. No paid subscriptions to Dropbox/Google Drive/Onedrive. 
3. No vendor lock-in: mostly open source based software gives you freedom to choose whatever platform you like (Android/iOS/Windows/Ubuntu/Web). 
4. No vendor lock-out: moving from iOS to Android? Figuring out how to get your data migrated can be a hassle. 
5. Because it is really cool, energy efficient and you can support your family, extended family with your server, so that they don't run in to the limitations that paid cloud solutions come with. 

## Why self-build? Just buy a Synology or QNAP..?
9 reasons: 
1. A self-build (hardware) server can be 5 times more power efficient. Imagine this system will be powered on 24/7/365. A Synology or QNAP can easily consume 8-15W in idle, while a self-build server can achieve idle power consumption of less than 5W (some even less than 3W). That is probably less than most of your electronic devices *on standby*. 
2. It will allow you to install any service you might need and is very future-proof as you can add services easily in the future, without vendor lock-in. 
3. A self-build homeserver is simply much faster, as it will contain a much faster CPU and more/faster RAM and modern SSD to run the applications. 
4. Scalability & upgrades: you can easily add a cheap SSD as cache or add HDDs if you need more space. 
5. In case of issues or disaster, you have the maximum set of options to restore data or resolve the issue, as you have designed the system yourself (with help of this guide). 
6. Value for money: a Synology or QNAP is actually quite expensive and not very future proof: limited expansion options.
7. Some "ready to go" solutions require you to use specific storage systems that are overpriced. Synology is moving in that direction.
8. It is *NOT* simpler! You still need to do the hardest and time consuming part: configure your drives and organise your data.
9. Thanks to Docker and Docker-Compose, self-build is just as user friendly and simple as Synology to run cloud services for your users.

## What are the benefits of adopting your setup and config (fully or partially)?

 - A LOT OF CARE has gone into sane selections of the right tool, finding the best configuration,  
 - To allow everything to run fast, smooth, efficient and still be scalable. 
 - Sometimes things have been optimised to squeeze out maximum speed, even though it is not necessary (might be if you add lots of users). 
 - I have been a perfectionist and spent lots of time researching many tools, discussing with developers on fora, Discord, Reddit to figure out what would allow me to run my rock-stable server with as little as maintenance as possible.  
 - The tools listed here are only a small subset of the tools I have investigated as I sometimes spent a whole day researching alternatives.
 - Other guides only provide part of the equation. With my scripts, you can litteraly start from scratch. 

## Can I use the server as PC or workstation? But I have never used Ubuntu..
You can, I do. Switched cold-turkey from Windows. You can find my [post-installation automated script for Manjaro OS](https://github.com/zilexa/manjaro-gnome-post-install) here, as it perfectly matches the prep-server.sh script that is central in this Guide. The post-install script is how I configure PCs for parents and friends, after running the script they are good to go, it even adds Macbook-like touchpad gestures. It also installs carefully selected common tools.

