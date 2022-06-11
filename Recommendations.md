## Hardware recommendations

A lot of research has been done to determine the required choices to have a rock stable, future-proof homeserver with the lowest power consumption.
The system will be running 24/7, so power consumption matters. With this combination you should be able to reach idle power consumption of 4 watt.

The research can be found in [this Dutch forum](https://gathering.tweakers.net/forum/list_messages/1673583) (or see [translation](https://translate.google.com/translate?hl=&sl=nl&tl=en&u=https%3A%2F%2Fgathering.tweakers.net%2Fforum%2Flist_messages%2F1673583)), the first post is long and contains the most important information. Below the concluding recommendations: 

## Motherboard
_non-gaming, Intel for lowest power consumption, ECC memory support_

The most important part that goes against most online recommendations:  
1. A motherboard designed specifically for 24/7/365 stable operation with low power consumption - Fujitsu (now: Kontron) D3644-B.  \
This is the cheapest (yet feature-complete) motherboard with the C246 chipset, one that is specifically meant for embedded devices and edge solutions. It is made of special components for low power consumption and stability. **Almost every other motherboard you find is made up of components focused on performance (for gaming usually)**. Building a home server requires you to think differently. For example. you do not want a motherboard with maximum number of phases, because they exist solely to support high consumption of your CPU. This goes against the philosophy behind this guide: creating a highly efficient, stable, durable, high availability had high performance home server. The Fujitu D3644-B, D3643-H, D3473-B motherboards are smart choices. Unfortunately only the 3644 supports ECC. There are however Asrock motherboards out there with low power consumption and ECC. 

2. There are no AMD chipsets/motherboards with a similar focus (non-gaming) and no combination of AMD motherboard+AMD processor has such low idle power consumption (2-5 WATT).

3. combined with an Intel Pentium Gold (5400 or newer, not much difference between the old and new ones) your system will be plenty fast. Or go for a quad core i3-8100, i3-9100 or i3-10100 (choose the cheapest one as they are near-identical). They support ECC RAM and hardware transcoding of video and especially the quad-cores are plenty fast for the next 10+ years as a homeserver. 

4. Error-correcting memory (non-registered/unbuffered ECC RAM) - even normal computers should have this. Prevents data and disk corruption issues. Very important! Unfortunately due to Intel strategy, very few motherboards support (non-reg) ECC.

5. If you do have an addiction to the highest speed, even though NVME/PCI Express is not recommended for data storage (see Storage section), go for a Motherboard with PCI-Express bifurcation support. In the future when ssds become cheaper, you can replace SATA drives for M.2 drives. You can insert 4 M.2 SSDs with full PCIe 4x speed in a PCIe 16x port. With the Fujitsu/Kontron 3644 motherboard, you can add in total 5x NVME PCI Express 3.0 x4 M.2 SSDs with full speed in addition to the 6 SATA slots.

## Power consumption
7. PicoPSU-90 & Leicke 120W adapter - extremely efficient at low power consumption. Normal PSUs are only efficient at higher consumption levels (doesn't make sense for a 24/7 homeserver).

## Storage
- For the OS and applications, use an NVME drive, for example M.2 PCI Express 3.0 x4 are common. PCI 4.0 uses more power and the extra speed is useless for our purpose. Choose the M.2 NVME SSD with low idle power consumption. There are big differences, look for Anandtech, Tomshardware reviews. Most other reviewers do not test idle power consumption at all! Even though on a 24x7 system, this will be THE power consumption 90% of the time. The following have very low idle power consumption:
  - Samsung PM981a
  - WesternDigital SN730
  - Kioxia G6 
- For data storage, backups etc use SATA instead of NVME: SATA SSDs offer plenty of speed (up to 550MB/s) and use less power. They are also cheaper. There are very little usecases for NVME/PCI Express as storage drives in a NAS/Homeserver.
- When using harddisks, go for 2.5" instead of 3.5" because they use up to 5 times less power, even when idle. Instead of buying the SATA harddisks, buy the Seagate Portable Drive or Seagate Backup Plus 4TB or 5TB: they cost half the price and contain a normal SATA controller. Just remove them from the usb case first. 
