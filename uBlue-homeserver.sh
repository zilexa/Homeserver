# Switching to Bluefin OS (Fedora Silverblue based), attempting to use podman instead of docker
# So far, after a clean install, these are the required steps

# Change hostname, note you can also just do this in Settings

Basics after a new laptop/pc install (Gnome based Linux): 

1. Go to Settings > System > Region
   > Change Formats to your region. 
2. Settings > System > About 
   > Change your device name
3. Settings > System > Remote Desktop
   > Enable Desktop Sharing & Remote Control
   > Set a password you remember
4. Settings System > SSH
   > Enable SSH
5. Settings > Power 
   > Disable Suspend when plugged in if this is a device that will be running 24x7
6. Close Settings and go to Apps > Extensions
   > Find TailscaleQS
   > Hit the tiny arrow at the right to see its description.
   > Note it says to run a command first.
   > Open Terminal app, type over that command and run it. 
7. > Now you can run `tailscale up` and it will give you an URL to login. When done:
   > Go to the system tray, hit the arrow next to Tailscale > Settings. 
   > Enable "Allow LAN Access". The rest disabled. 

8. Tailscale Exit Node: If this is your homeserver/nas that will be running 24x7, you can use it as a Tailscale Exit Node, and optionally allow other devices to tunnel
   their traffic through this server (for example: to share Netflix). This turns your system into a VPN Tunnel endpoint (like a paid VPN service does). 
   This is NOT needed for other devices to access services running on this server. But its a nice to have option:
   > run: tailscale set --advertise-exit-node
   > go on the web to tailscale.com and login to admin console, there you can Approve your device as exit node. 
   > You need to also run: tailscale set --advertise-routes=192.168.1.0/24
   > and probably accept this in the webUI. 
   > Now go to the system tray, make sure "Allow LAN Access" and "Accept Routes" are enabled. Make sure "Allow DNS" is disabled since you don't need adfiltering. 
   Note: "Accept Routes" only needs to be enabled if you set this device up as Exit Node. Otherwise leave it disabled.
   

sudo hostnamectl hostname obelix.o

# Allow services running under current user to linger after logout
ctl enable-linger $USER

# Add registry for docker images
##mkdir $HOME/.config/containers/
##cp /etc/containers/registries.conf $HOME/.config/containers/

# Lower privileged ports
##sudo nano /etc/sysctl.d/podman-privileged-ports.conf
# add net.ipv4.ip_unprivileged_port_start=80 to this file
# Apply change:
##sudo sysctl --load /etc/sysctl.d/podman-privileged-ports.conf

Instead of the above, use the Bluefin-provided method to setup Docker: ujust dx-group

# To manage containers via Cockpit, note this is optional and should NOT be used! Just use Podman Desktop isntead!!
## rpm-ostree install cockpit-system cockpit-ws cockpit-files cockpit-networkmanager cockpit-ostree cockpit-podman cockpit-selinux cockpit-storaged
# REBOOT!
# Configure cockpit
##sudo systemctl enable --now cockpit.socket
##sudo firewall-cmd --add-service=cockpit
##sudo firewall-cmd --add-service=cockpit --permanent
##sudo setsebool -P nis_enabled 1

# Configure podman
##systemctl --user enable --now podman.socket
## Enable GPU access for hardware accelerated video transcoding (for Jellyfin)
sudo setsebool -P container_use_dri_devices 1

# Change SELinux to permissive mode (or disable), permissive mode will show warnings, not block anything:
sudo nano /etc/selinux/config
change to SELINUX=permissive
Save changes and reboot. 
# Thats it.. all other modifications should be in the compose file.. 
