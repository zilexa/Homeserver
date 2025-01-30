# Switching to Bluefin OS (Fedora Silverblue based), attempting to use podman instead of docker
# So far, after a clean install, these are the required steps

# Change hostname
sudo hostnamectl hostname obelix.o

# Allow services running under current user to linger after logout
ctl enable-linger $USER

# Install required system apps
rpm-ostree install podman-compose cockpit-podman
ujust cockpit

# Allow containers to access GPU directly for hardware acceleration (required for Jellyfin)
sudo setsebool -P container_use_dri_devices 1

# Add registry for docker images
❯ cp /etc/containers/registries.conf $HOME/.config/containers/

# Temp solution: lower priv ports. A better solution would be to use firewall rules - to figure out later. First want to get the containers up and running again
sudo nano /etc/sysctl.d/podman-privileged-ports.conf
# add net.ipv4.ip_unprivileged_port_start=80 to this file
# Apply change:
sudo sysctl --load /etc/sysctl.d/podman-privileged-ports.conf

# Create required network for cadyy
podman network create net-caddy

# Thats it.. all other modifications should be in the compose file.. 
