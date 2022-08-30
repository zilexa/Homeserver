## Hardware recommendations

A lot of research has been done to determine the required choices to have a rock stable, future-proof homeserver with the lowest power consumption.
The system will be running 24/7, so power consumption matters! With the recommendations below you should be able to reach idle power consumption of 2.5W up to 8W.

- Goal 1: find parts with the lowest power consumption or parts that have high efficiency (wich is variable based on consumption) at low wattage. 
- Goal 2: identify parts specifically built to run continuously 24x7x365 (which is often the opposite of parts built for gaming/performance!)

The research can be found in [this Dutch forum](https://gathering.tweakers.net/forum/list_messages/2096876) (or see [translation](https://gathering-tweakers-net.translate.goog/forum/list_messages/2096876?_x_tr_sl=nl&_x_tr_tl=en&_x_tr_hl=nl&_x_tr_pto=wapp)), the first post is long and contains the most important information. Below the concluding recommendations: 

## Barebones
If you your storage needs are limited and you do not want to build your own system (which can be both expensive and time consuming and if you never build a PC before, it might not be for you), these barebones (complete systems, just add memory and storage) have been tested to have very low power consumption: 
- ASRock DeskMini 310 (looks big but is small, 2x SATA + 1 M.2 drive).
- Intel NUC NUC8i3BEH (1 SATA drive + 1 M.2 drive) can do <3.5W idle.
- Intel NUC Kit NUC8i5BEH (1 SATA drive + 1 M.2 drive can do <3.5W idle. The i5 processor is overkill, but if you can't find the i3 version its a good alternative.
- [NUC10i7FNH](https://www.anandtech.com/show/15571/intel-nuc10i7fnh-frost-canyon-review) (1 SATA drive + 1 M.2 drive). Anandtech measured 4.64W.
- [Minisforum UM820](https://arstechnica.com/gadgets/2021/02/looking-for-a-tiny-but-powerful-pc-check-out-the-minisforum-u820-u850/) (2x SATA + 1 M.2 drive) same size as a NUC, similar to the NUC8i3BEH but with updated GPU.  

If you do consider building your own server, read on: 
## Motherboard 
_*non-gaming, with parts focused on power consumption/efficiency, with ECC memory support*_  \
The most essential part: A motherboard designed specifically for 24/7/365 stable operation with low power consumption, instead of a motherboard designed for gaming.
  - (with ECC memory support) mATX: Fujitsu D3644-B mATX (supports ECC)
    - (no ECC) mATX alternatives: Fujitsu D3642-B or D3643-H
  - (no ECC) mITX: Fujitsu D3473-B 
  - ASRock H310M-STX, only available with case (barebone): AsRock DeskMini 310 

The D3644-B is the cheapest (yet feature-complete) motherboard with the C246 chipset, one that is specifically meant for embedded devices and edge solutions. It is made of special components for low power consumption and stability. **Almost every other motherboard you find is made up of components focused on performance (for gaming usually)**. 
Building a home server requires you to think differently. For example. you do not want a motherboard with maximum number of phases, because they exist solely to support high consumption of your CPU. This goes against the philosophy behind this guide: creating a highly efficient, stable, durable, high availability had high performance home server. The B motherboards are smart choices. Unfortunately only the 3644 supports ECC. 

_Notes_
1. Motherboards designed to run uninterrupted 24x7x365 like the D3644-B are not refreshed yearly like consumer-focused products. They are being produced for many years and receive lots of support. Newer technologies are usually focused on performance and is therefore not relevant. Intel has the C246 chipset specifically for embedded/continuously running systems.  This special chipset has not seen a successor yet, simply because no new technologies have been released that would be beneficial for such systems. 

2. There are no AMD chipsets/motherboards with a similar focus (non-gaming) and no combination of AMD motherboard+AMD processor has such low idle power consumption (2-5 WATT).

3. Although the importance of error-correcting memory cannot be ignored, Intel has denied consumers to reap its benefits. You need a motherboard, CPU and memory that supports it. Most Intel chipset motherboards do not support ECC (unbuffered).  


## CPU 
_*(with ECC support)*_  \
Error-Correcting RAM is beneficial for most purposes and should be more mainstream. Unfortunately, Intel uses this feature to upsell their Xeon line-up in favor of their Core and Pentium line-up. While the Core-i3 8100 and Core i3 9100 support ECC memory, the 10th and 12th gen Core CPUs do not support ECC! Luckily, the 10th generation cpu (Core i3 10100) is marginally faster than both the 9100 and the 8100. Pick one of those two based on which one has the lowest price.

_Notes_
- Since the Intel 8th gen, Core i3 series are always quad-core. The i3-8100 is comparable to the i5-7100. The i3-8100 therefore has plenty of power available for homeserver purposes and is even powerful enough to use in a system that will function both as homeserver and as regular desktop PC.
- The upgrade to 9100 is not massive. Still the 9100 is a great choice and also supports Intel QuickSync for video encoding/transcoding, which is required if you want to stream your movies/series to devices outside your home network. 
- I am an AMD-fan, since the K6-II, but AMD idle power consumption is much higher. Makes sense as their market is gamers/people seeking high performance. 
- There are rumours Intel will release Core CPUs with ECC again, however, since there is no new motherboard coming anytime soon, there is no reason to wait for it. The 9100/8100 Core i3 really have all the performance you need. 


## Memory (RAM)
_*(unbuffered/non-registered ECC)*_  \
2x8GB is plenty for most needs, but highly depends on what you plan to do with your server. I am running 26 docker containers and still use only 6GB to 12GB max. Yet it can be preferred to have lots of free RAM for specific tasks. If budget allows, consider 2x16GB. 
Unbuffered ECC RAM is highly recommended for a homeserver/storage solution has it helps prevent data corruption, not just in-memory, but also prevent such corruption to be written to your storage drives, which usually leads to common read errors (and may lead you to the conclusion the storage drive is faulty). 

_Notes_
1. Error-correcting memory (non-registered/unbuffered ECC RAM) - even normal computers should have this. Prevents data and disk corruption issues. Very important! Unfortunately due to Intel strategy, very few motherboards support (non-reg/unbuffered) ECC.

2. Always download the Memory Compatibility List of your motherboard and find compatible memory. 

3. Do not worry about the DDR5 hype.  DDR5 is developed for performance and should not be preferred for a homeserver. Besides that, DDR5 has its own power management chip, this means differences per brand/model/revisions. Also, ECC DDR5 is not common yet and ECC DDR5 has a form of ECC that only signals a problem with a data refresh on the module itself. That's called on-die ECC. It does not detect erroneous data going to the processor/cache. It is therefore not fail-safe at the single bit level. Until tests/reviews provide arguments in favor of (ECC) DDR5 for 24x7x365 low power consumption, stick with ECC unbuffered/non-registered DDR4.

## Power Suppply
A PicoPSU (as small as the motherboard power plug itself) is the king of PSUs up to 15W idle while still capable of handling peaks, for example at boot or when harddrives spin-up. Normal PSUs are only efficient at higher consumption levels (doesn't make sense for a 24/7 homeserver). Stability is also dependent on power delivery. The PicoPSU90 and higher models with a proper power adapter will contribute to a rock-stable system. 
- PicoPSU 80: if you only use SSDs or have up to 3-4 2.5" HDDs and no other components with high consumption (for example 2.5Gbit ethernet). Note its cable is short and you will need to buy the P4 cable seperately (required to feed the CPU). 
- PicoPSU 90: This one comes with P4 cable.
- PicoPSU 160XT: for systems with more harddisks. Less efficient than the PicoPSU 80. 

There is a great difference in power adapters when it comes to efficiency and overhead, and it varies depending on the power demand of the sysyem. All of the following options are great choices. A great, in-depth review can be found [here](https://mrmrmr.tweakblogs.net/blog/19706/efficiency-tests-van-12v-adapters-voor-zuinige-servers), English version [here](https://mrmrmr-tweakblogs-net.translate.goog/blog/19706/efficiency-tests-van-12v-adapters-voor-zuinige-servers?_x_tr_sl=nl&_x_tr_tl=en&_x_tr_hl=nl&_x_tr_pto=wapp). 
- Highest efficiency/lowest overhead when idle consumption is below 10W: 
  - 96W: FSP FSP096-AHAN3 
  - 120W: XP Power VES120PS (price is 2x the Leicke adapter)
- Highest efficiency/lowest overhead when idle consumption is above 10W: 
  - 60W: FSP060-DHAN3
  - 60W: Seasonic SSA-0601HE-12
  - 84W FSP084-DHAN3
  - 120W: Leicke NT03015 (fantastic low budget option)

_Notes_  \
The Leicke is a great, affordable option for <10 W and >10W, there are just a few adapters that have even less overhead when <10W. Consider that before you spend too much on the power adapter. 


## Storage
- For the OS and applications, use an NVME drive, for example M.2 PCI Express 3.0 x4 are common. PCI 4.0 uses more power and the extra speed is useless for our purpose. Choose the M.2 NVME SSD with low idle power consumption. There are big differences, look for Anandtech, Tomshardware reviews. Most other reviewers do not test idle power consumption at all! Even though on a 24x7 system, this will be THE power consumption 90% of the time. The following have very low idle power consumption:
  - Samsung PM981a or newer (PM9A1)
  - WesternDigital SN730
  - Kioxia G6 
- For data storage, backups etc use SATA instead of NVME: SATA SSDs offer plenty of speed (up to 550MB/s) and use less power. They are also cheaper. There are very little usecases for NVME/PCI Express as storage drives in a NAS/Homeserver.
  - Samsung EVO 850
  - Samsung EVO 860
  - Samsung QVO 870 (<-- cheapest 4TB SSD, performs better than lots of (more expensive) TLC drives, highly recommended) 
- When using harddisks, go for 2.5" instead of 3.5" because they use up to 5 times less power, even when idle. Instead of buying the SATA harddisks, buy the Seagate Portable Drive or Seagate Backup Plus 4TB or 5TB: they cost half the price and contain a normal SATA controller. Just remove them from the usb case first. 
  - **_Some users (including me) have had bad experiences with the 2.5" Seagate 4TB and 5TB models, extremely low performance (<30MB/s!) once its cache is full, loud ticking noises; untrustworthy drives. Every 2.5" HDD with >2TB capacity is a so called SMR drive. Google and understand what this means. You might want to opt for non-SMR drives, which automatically means 3.5" HDDs or SATA SSDs if you need >2TB capacity drives._**

_Notes_
1. If you do have an addiction to the highest storage speed and have your mind set on using NVME, go for a Motherboard with PCI-Express bifurcation support (D-3644 and most other Fujitsus support this). PCI-Express bifurcation allows you to use a single PCI-Express port as multiple ports natively, without expensive, energy-slurping bridge chips. PCI Bifurcation splitter cost only 20 bucks and allows you to connect up to 4 NVME SSDS (PCI-E3.0 x4 speed) in a single x16 slot. 
In the future when ssds become cheaper, you can replace SATA drives for M.2 drives. You can insert 4 M.2 SSDs with full PCIe 4x speed in a PCIe 16x port. With the Fujitsu/Kontron 3644 motherboard, you can add in total 5x NVME PCI Express 3.0 x4 M.2 SSDs with full speed in addition to the 6 SATA slots.

2. Better start with organizing your data. I started with 5x 5TB 2.5" HDDs + 1TB NVME SSD (via PCI Bifurcation) for data storage and backups (15TB for data, 10TB for backups, 1TB for cache) in addition to my 512GB NVME SSD for OS. 2 years later and I regret the waste of money as I only have 600GB of personal data (excluding backups/snapshots to go back in time) and only need a 2TB drive for my downloads. I am switching completely to 4TB SATA SSDs (Samsung EVO 860 and QVO 870 bought secondhand). 
