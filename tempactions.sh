# Switching to Bluefin OS (Fedora Silverblue based), attempting to use podman instead of docker
# So far, after a clean install, these are the required steps

# Change hostname
sudo hostnamectl hostname obelix.o

# Allow services running under current user to linger after logout
ctl enable-linger $USER

# Add registry for docker images
mkdir $HOME/.config/containers/
❯ cp /etc/containers/registries.conf $HOME/.config/containers/

# Lower privileged ports
sudo nano /etc/sysctl.d/podman-privileged-ports.conf
# add net.ipv4.ip_unprivileged_port_start=80 to this file
# Apply change:
sudo sysctl --load /etc/sysctl.d/podman-privileged-ports.conf

# Install required system apps
rpm-ostree install podman-compose cockpit-system cockpit-ws cockpit-files cockpit-networkmanager cockpit-ostree cockpit-podman cockpit-selinux cockpit-storaged
# REBOOT!
# Configure cockpit
sudo systemctl enable --now cockpit.socket
sudo firewall-cmd --add-service=cockpit
sudo firewall-cmd --add-service=cockpit --permanent
sudo setsebool -P nis_enabled 1

# Configure podman
systemctl --user enable --now podman.socket
## Enable GPU access for hardware accelerated video transcoding (for Jellyfin)
sudo setsebool -P container_use_dri_devices 1


# Thats it.. all other modifications should be in the compose file.. 
