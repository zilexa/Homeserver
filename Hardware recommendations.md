A lot of research has been done to determine the required choices to have a rock stable, future-proof homeserver with the lowest power consumption.
The system will be running 24/7, so power consumption matters. With this combination you should be able to reach idle power consumption of 4 watt.

- A motherboard designed specifically for 24/7/365 stable operation with low power consumption - Fujitsu D3644-B.
- Error-correcting memory (non-registered/unbuffered ECC RAM) - even normal computers should have this. Prevents data and disk corruption issues.
- 2.5" harddrives - compared to 3.5" they use up to 5 times less power, even when idle. These USB disks contain normal data controller and are cheaper than the internal versions. Just remove them from the usb case.
- Samsung PM981a or WesternDigital D SN550 ssd for system/os - they have the lowest idle power consumption (tomshardware.com).
- PicoPSU-90 & Leicke 120W adapter - extremely efficient at low power consumption. Normal PSUs are only efficient at higher consumption levels (doesn't make sense for a 24/7 homeserver).

Optional:
- WesternDigital SN550 1tb ssd for a fast cache to complement the 2.5" disks.
- Motherboard with PCI-Express bifurcation support (add 4 ssds in a single x16 PCI-Express slot). In the future when ssds become cheaper, you can replace drives for M.2 drives.
