#version=RHEL8
ignoredisk --only-use=sda

# Partition clearing information
clearpart --none --initlabel

# Use graphical install
# graphical

# Use CDROM installation media
cdrom
text

# Keyboard layouts
keyboard --xlayouts='br'

# System language
lang en_US.UTF-8

# Use network installation
url --url="http://dl.rockylinux.org/pub/rocky/8.6/BaseOS/x86_64/os/"

# Firewall information
firewall --enabled --service=ssh

# Network information
network  --bootproto=dhcp --ipv6=auto --activate
network  --hostname=rl8-6.localdomain

repo --name="AppStream" --baseurl=http://dl.rockylinux.org/pub/rocky/8.6/AppStream/x86_64/os/
repo --name="BaseOS" --baseurl=http://dl.rockylinux.org/pub/rocky/8.6/BaseOS/x86_64/os/

# Root password
rootpw --iscrypted $6$4buGu5Vw7TCmOjXv$Jxtd.W7i1XprZaGA5yem2icnNmTAt.8VM3RspvnYhtoWw548Itrr5uVuQiz3/6OSFBqdTSr4t.DsXxzOYeTpM0

# Run the Setup Agent on first boot
firstboot --disabled

# Do not configure the X Window System
skipx

# System services
services --disabled="kdump" --enabled="NetworkManager,sshd,rsyslog,chronyd,cloud-init,cloud-init-local,cloud-config,cloud-final,rngd,qemu-guest-agent"

# System timezone
timezone America/Sao_Paulo --isUtc

# Disk partitioning information
part / --fstype="xfs" --grow --size=6144
part swap --fstype="swap" --size=512
reboot

%packages --ignoremissing --excludedocs
@core
NetworkManager
chrony
cloud-init
cloud-utils-growpart
cockpit-system
cockpit-ws
dhcp-client
dnf
dnf-utils
dracut-config-generic
dracut-norescue
firewalld
gdisk
grub2
kernel
nfs-utils
python3-jsonschema
qemu-guest-agent
rng-tools
rocky-release
rsync
tar
yum
yum-utils
traceroute
wget
telnet
OpenIPMI
ipmitool
git
nano
kexec-tools
bind-utils
zip
net-tools
nfs-utils
nfs4-acl-tools
jq
patch
bzip2

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

# Manage devops access
groupadd -g 1000 devops
useradd -m -g 1000 -u 1001 devops
mkdir /home/devops/.ssh

echo -e "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC/NI0Q4dJJt3pubtl496YHP7kLx7eCkOOZF8KN7gn5uyYozDeHdBgYcG8WfJnEOT1tqTBBNAKyLP8RFGNuMPkiPvwyvJ8lIe/vubIzMxAkStr59/KoET2gEsBsZTCbRYEpyFgbMfuiz5bEaX/kK2A5ISWIzKwtyHygp2mocpRl3be/xjC6LhHVmYi0oIRHI5PkVjdf545gKZHnklwnmuXcNtjJ9H0uelw1a1UWDhXYmgLCdG9tbNSeoFe9cWL+c/IibvvjQHo5F8E8yoLhXjai+cMaFblH2oIjCl+HD/47DPKz0EBbvjq7XwpjKzPLFnQiCm7S1eAqit/Qn4M0/PpktGBb8U/SDbtM9zdFF0H74iVhw8frL/EiPslwOK3Uz43QpgKTuJQvCOIGR4k4Sizer60J2FDSQSx17PYMQs225HVAgcd2JPGwDaqIw69Rt4DfYbzeknn7/aYmTkQ6u43RxyGTS6AfyCxAwt1U6ry0qqJE0e1GeZEC7S489FVnqMU= edleson@DESKTOP-SPBKIGG" >  /home/devops/.ssh/authorized_keys
chown -R devops:devops /home/devops/.ssh
chmod 700 /home/devops/.ssh
chmod 600 /home/devops/.ssh/authorized_keys

echo "devops ALL=(ALL:ALL) NOPASSWD:ALL" > /etc/sudoers.d/devops
chmod 440 /etc/sudoers.d/devops

systemctl enable vmtoolsd
systemctl start vmtoolsd

# this is installed by default but we don't need it in virt
echo "Removing linux-firmware package."
yum -C -y remove linux-firmware

# Remove firewalld; it is required to be present for install/image building.
echo "Removing firewalld."
yum -C -y remove firewalld --setopt="clean_requirements_on_remove=1"

# remove avahi and networkmanager
echo "Removing avahi/zeroconf and NetworkManager"
yum -C -y remove avahi\* 

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
mkdir -p /var/cache/yum
/usr/sbin/fixfiles -R -a restore

# reorder console entries
sed -i 's/console=tty0/console=tty0 console=ttyS0,115200n8/' /boot/grub2/grub.cfg

yum update -y
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers
yum clean all

%end

%anaconda
pwpolicy root --minlen=6 --minquality=1 --notstrict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --notstrict --nochanges --emptyok
pwpolicy luks --minlen=6 --minquality=1 --notstrict --nochanges --notempty
%end
