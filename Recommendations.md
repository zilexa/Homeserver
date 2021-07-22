## Hardware recommendations

A lot of research has been done to determine the required choices to have a rock stable, future-proof homeserver with the lowest power consumption.
The system will be running 24/7, so power consumption matters. With this combination you should be able to reach idle power consumption of 4 watt.

The research can be found in [this Dutch forum](https://gathering.tweakers.net/forum/list_messages/1673583) (or see [translation](https://translate.google.com/translate?hl=&sl=nl&tl=en&u=https%3A%2F%2Fgathering.tweakers.net%2Fforum%2Flist_messages%2F1673583)), the first post is long and contains the most important information. Below the concluding recommendations: 

The most important part that goes against most online recommendations:
1. A motherboard designed specifically for 24/7/365 stable operation with low power consumption - Fujitsu D3644-B. This is the cheapest (yet feature-complete) motherboard with the C246 chipset, one that is specifically meant for embedded devices and edge solutions. It is made of special components for low power consumption and stability. **Almost every other motherboard you find is made up of components focused on performance (for gaming usually)**. Building a home server requires you to think differently. For example. you do not want a motherboard with maximum number of phases, because they exist solely to support high consumption of your CPU. This goes against the philosophy behind this guide: creating a highly efficient, stable, durable, high availability had high performance home server. The Fujitu D3644-B, D3643-H, D3473-B motherboards are smart choices. Only the 3644 supports ECC. 

2. There are no AMD chipsets/motherboards with a similar focus and no combination of AMD motherboard+AMD processor has such low idle power consumption (2-5 WATT).

3. combined with an Intel Pentium Gold (5400 or newer, not much difference between the old and new ones) your system will be plenty fast. Or go for a quad core i3-8100, i3-9100 (choose the cheapest one as they are near-identical). They support ECC RAM and hardware transcoding of video and especially the quad-cores are plenty fast for the next 10+ years as a homeserver. 

4. Error-correcting memory (non-registered/unbuffered ECC RAM) - even normal computers should have this. Prevents data and disk corruption issues.

5. 2.5" harddrives - compared to 3.5" they use up to 5 times less power, even when idle. Instead of buying the SATA harddisks, buy the Seagate Portable Drive or Seagate Backup Plus 4TB or 5TB: they cost half the price and contain a normal SATA controller. Just remove them from the usb case first. 

6. Samsung PM981a or WesternDigital SN550 ssd for system/os - they have the lowest idle power consumption (tomshardware.com).

7. PicoPSU-90 & Leicke 120W adapter - extremely efficient at low power consumption. Normal PSUs are only efficient at higher consumption levels (doesn't make sense for a 24/7 homeserver).

Optional:
- WesternDigital SN550 1tb ssd for a fast cache to complement the 2.5" disks.
- Motherboard with PCI-Express bifurcation support. In the future when ssds become cheaper, you can replace drives for M.2 drives. You can insert 4 M.2 SSDs with full PCIe 4x speed in a PCIe 16x port. With the 3644 motherboard, you can add in total 5 M.2 SSDs with full speed, in addition to the M.2 port on the motherboard and 6 SATA slots. This allows you to transform your server into an SSD-based server in 5-10 years. 
