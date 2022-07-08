#version=RHEL8
ignoredisk --only-use=sda
# Partition clearing information
clearpart --none --initlabel

# Use CDROM installation media
cdrom
# Use graphical install
graphical
# text
# Keyboard layouts
keyboard --xlayouts='br'
# System language
lang en_US.UTF-8
# Firewall information
firewall --enabled --service=ssh
# Network information
network  --bootproto=dhcp --activate
network  --hostname=rl8-6.localdomain
# Repos
# repo --name="AppStream" --baseurl=http://dl.rockylinux.org/pub/rocky/8.6/AppStream/x86_64/os/
# repo --name="BaseOS" --baseurl=http://dl.rockylinux.org/pub/rocky/8.6/BaseOS/x86_64/os/
# Use network installation
# url --url="http://dl.rockylinux.org/pub/rocky/8.6/BaseOS/x86_64/os/"

# Run the Setup Agent on first boot
firstboot --disabled
# Do not configure the X Window System
skipx
# System services
# services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd,qemu-guest-agent"
# System timezone
timezone America/Sao_Paulo --isUtc
# Root password
rootpw --iscrypted $6$n4DQUg67g7VjVmXe$SqqPdv66Uv01Krh1LzeFmI2dSMqoQIlIhrrD.jCiDIlYGYUoSl5mmODpXm5bBnw5GtyJ56.IgMG2fnqlyYDsN0
# Admin user
user --groups=wheel --name=k3t-user --password=$6$wKC3PBcKxuQGUY4L$2YsRElu9W4jW3.76nGu.f1eVXg3UXwp1Dzm7z3TQ5PTkKAe4GgKsvwQzzTrhw0hhzfOXB8ukphB0j8yJstzpJ0 --iscrypted --uid=1000 --gecos="K3T Admin User" --gid=1000

# Disk partitioning information
# part / --fstype="xfs" --grow --size=6144
# part swap --fstype="swap" --size=512
# Disk partitioning information
part pv.302 --fstype="lvmpv" --ondisk=sda --size=32255
part /boot --fstype="xfs" --ondisk=sda --size=512
volgroup rocky --pesize=4096 pv.302
logvol swap --fstype="swap" --size=1024 --name=swap --vgname=rocky
logvol / --fstype="xfs" --size=31227 --name=root --vgname=rocky

reboot

%packages --ignoremissing --excludedocs
@^minimal-environment
# @core
# NetworkManager
# chrony
# cloud-init
# cloud-utils-growpart
# cockpit-system
# cockpit-ws
# dhcp-client
# dnf
# dnf-utils
# dracut-config-generic
# dracut-norescue
# firewalld
# gdisk
# grub2
# kernel
# nfs-utils
# python3
# python3-jsonschema
# qemu-guest-agent
# rng-tools
# rocky-release
# rsync
# tar
# dnf
# dnf-utils
# traceroute
# wget
# telnet
# OpenIPMI
# ipmitool
# git
# nano
# kexec-tools
# bind-utils
# zip
# net-tools
# nfs-utils
# nfs4-acl-tools
# jq
# patch
# bzip2
# htop
# parted

# unnecessary firmware
-aic94xx-firmware
-atmel-firmware
-b43-openfwwf
-bfa-firmware
-ipw2100-firmware
-ipw2200-firmware
-ivtv-firmware
-iwl100-firmware
-iwl1000-firmware
-iwl3945-firmware
-iwl4965-firmware
-iwl5000-firmware
-iwl5150-firmware
-iwl6000-firmware
-iwl6000g2a-firmware
-iwl6050-firmware
-libertas-usb8388-firmware
-ql2100-firmware
-ql2200-firmware
-ql23xx-firmware
-ql2400-firmware
-ql2500-firmware
-rt61pci-firmware
-rt73usb-firmware
-xorg-x11-drv-ati-firmware
-zd1211-firmware
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

%post

# dnf update -y

dnf install -y cloud-init cloud-utils-growpart qemu-guest-agent rsync

mkdir /home/k3t-user/.ssh
echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDih36iZoYeRyTjUwZI6Ec7UNzRW/498fqW0XCHysTtn5aQSpmrJAiBOWQ4aLWHnswRQaw3fR+hR7OQ9De9pOKe7i6vv35CQlnpeyVmQf0Yw3FYTbbCLi7YBuLPgqp+XMUSG/ugtEivn5ZYV3wjE1C3IETqceH2R8u5qbSuyHlW5DbuYoKyiLo0RXm+2Lpya+qKVV1lHYR04oJKNSN4xYRVngrMNTmOgUpm+1fH8K6NAtYHsTP97MnkAFi2wCgngANJ0HX7BI/zNMxYkH+X+aVuPyy5riRqbzIjCb4a0PBw9mHQExleiIbI+iB5VPqKyQaKEWe6I1O/iNvbjOasDarVroTkgdQM5RuT4mM+EQkB0gjrbtOxA4aV+MKbwdu1SIEu18sYnf/qkts8g27S3/aCWbhkXxvAyhbdHIRUNMtS1BJY/XJgSDz7zFKgBLMdsw9eCCcI8hAbVQSsFVe8vrDUPjPT/5KNLme3xX1E1FSKC4OApMeYTWNDl3wfoQ4zQPM= k3t-user@kode3" >  /home/k3t-user/.ssh/authorized_keys
chown -R k3t-user:k3t-user /home/k3t-user/.ssh
chmod 700 /home/k3t-user/.ssh
chmod 600 /home/k3t-user/.ssh/authorized_keys
echo "k3t-user ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/k3t-user
chmod 440 /etc/sudoers.d/k3t-user

systemctl enable qemu-guest-agent cloud-init
systemctl start qemu-guest-agent cloud-init

# permit root login via SSH with password authetication
echo "PermitRootLogin yes" > /etc/ssh/sshd_config.d/01-permitrootlogin.conf

# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
dnf -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
echo "Removing firewalld."
dnf -C -y remove firewalld --setopt="clean_requirements_on_remove=1"

# remove avahi and networkmanager
echo "Removing avahi/zeroconf and NetworkManager"
dnf -C -y remove avahi\* 

echo -n "Getty fixes"
# although we want console output going to the serial console, we don't
# actually have the opportunity to login there. FIX.
# we don't really need to auto-spawn _any_ gettys.
sed -i '/^#NAutoVTs=.*/ a\
NAutoVTs=0' /etc/systemd/logind.conf

# set virtual-guest as default profile for tuned
echo "virtual-guest" > /etc/tuned/active_profile

# Because memory is scarce resource in most cloud/virt environments,
# and because this impedes forensics, we are differing from the Fedora
# default of having /tmp on tmpfs.
echo "Disabling tmpfs for /tmp."
systemctl mask tmp.mount

cat <<EOL > /etc/sysconfig/kernel
# UPDATEDEFAULT specifies if new-kernel-pkg should make
# new kernels the default
UPDATEDEFAULT=yes

# DEFAULTKERNEL specifies the default kernel package type
DEFAULTKERNEL=kernel
EOL

# make sure firstboot doesn't start
echo "RUN_FIRSTBOOT=NO" > /etc/sysconfig/firstboot
echo "Fixing SELinux contexts."
touch /var/log/cron
touch /var/log/boot.log
mkdir -p /var/cache/dnf
/usr/sbin/fixfiles -R -a restore

# reorder console entries
# sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg
# sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

# UPGRADE KERNEL
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
dnf install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm -y
# dnf --enablerepo=elrepo-kernel install kernel-ml kernel-ml-headers -y # mainline kernel
dnf --enablerepo=elrepo-kernel install kernel-lt kernel-lt-headers -y # Long term suport
grub2-set-default 0
grub2-mkconfig -o /boot/grub2/grub.cfg

dnf clean all

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
