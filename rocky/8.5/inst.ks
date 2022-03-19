#version=RHEL8
# RHEL 8 - Install for Hadoop nodes
# VSE 20210620.01

# Installer options
graphical
keyboard --xlayouts='us'
lang en_US.UTF-8
timezone America/Sao_Paulo --isUtc --nontp
firstboot --enable
reboot
eula --agreed

repo --name="AppStream" --baseurl=file:///run/install/repo/AppStream

# Network information
network --bootproto=dhcp --device=eth0 --ipv6=ignore --activate --onboot=yes --hostname=localhost.localdomain
# network --bootproto=dhcp --device=eth1 --ipv6=ignore --activate --onboot=yes

# Disk partitioning information
ignoredisk --only-use=sda
clearpart --drives=sda --all --initlabel
part /boot --fstype="xfs" --ondisk=sda --size=1024
part pv.01 --fstype="lvmpv" --ondisk=sda --size=20480 --grow
volgroup sys --pesize=4096 pv.01
logvol swap --vgname=sys --name=swap --fstype="swap" --recommended
logvol / --vgname=sys --name=root --fstype="xfs" --size=30720 --label="os_root"

# Groups
group --name=ssh_access --gid=401

# System services
services --enabled="chronyd"
services --enabled="ipmi"
# module --name=modulename --stream=streamname

%packages --ignoremissing

# Plymouth is excluded to eliminate graphical boot
@^minimal-environment
kexec-tools
chrony
-plymouth
device-mapper-multipath
nano
tar
zip
bzip2
net-tools
nfs-utils
nfs4-acl-tools
bind-utils
git
patch
gcc
make
rpm-build
rpm-sign
traceroute
wget
telnet
OpenIPMI
ipmitool
%end

%addon com_redhat_kdump --enable --reserve-mb='auto'

%end

# Other Options: don't configure X Window
skipx
selinux --enforcing

# Enable kdump
%addon com_redhat_kdump --enable --reserve-mb='auto'
%end

# Pre-install activities
# %pre-install --interpreter=/usr/bin/bash --log /mnt/sysroot/root/pre-install.log
# 
# echo "Step: Pre-install"
# export MAC_ADDR=$( nmcli -p -e no --get-values GENERAL.HWADDR device show eth0 | tr [A-F:] [a-f-] )
# echo "MAC address: $MAC_ADDR"
# mkdir /mnt/sysroot/root/bin
# mkdir /mnt/ks
# mount -t nfs -o nfsvers=4,nolock,ro os-storage:/os/ks /mnt/ks
# cp /mnt/ks/satellite-6-registration-vse.sh /mnt/sysroot/root/bin
# if [ -f /mnt/ks/supplemental/hostnames ]; then
#   H=$( grep $MAC_ADDR /mnt/ks/supplemental/hostnames | cut -d' ' -f2 )
#   if [[ $H ]]; then
#     echo "Found hostname: $H" 
#     echo $H > /mnt/sysroot/root/hostname.tmp
#   fi
# fi
# cp /mnt/ks/supplemental/dell-system-update.repo /mnt/sysroot/etc/yum.repos.d
# echo "Pre-install activities complete"
# %end

# Post-install activities (runs in installed system unless --nochroot option is used)
# %post --interpreter=/usr/bin/bash --log /root/post-install.log
# 
# set -x
# echo "Step: Post-install"
# # See if we found a hostname from pre-install step
# if [ -f /root/hostname.tmp ]; then
#   export H=$( cat /root/hostname.tmp )
#   echo "Setting hostname to $H"
#   echo $H > /etc/hostname
# fi
# 
# # Get info about just-installed system
# source /etc/os-release
# export NAME ID VERSION_ID
# 
# # Mount NFS install repos
# mkdir -p /srv/osfiles
# echo "os-storage:/os/osfiles /srv/osfiles nfs _netdev,nfsvers=4,sec=sys 0 0" >> /etc/fstab
# 
# # Configure repos for dnf/yum
# 
# cat <<EOF > /etc/yum.repos.d/nfs.repo
# [nfs-baseos]
# name=Local $NAME $VERSION_ID BaseOS
# baseurl=file:///srv/osfiles/$ID/$VERSION_ID/BaseOS
# enabled=1
# gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
# 
# [nfs-appstream]
# name=Local $NAME $VERSION_ID AppStream
# baseurl=file:///srv/osfiles/$ID/$VERSION_ID/AppStream
# enabled=1
# gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
# EOF
# 
# %end

%post


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

#echo "Zeroing out empty space."
# This forces the filesystem to reclaim space from deleted files
# dd bs=1M if=/dev/zero of=/var/tmp/zeros || :
# rm -f /var/tmp/zeros
# echo "(Don't worry -- that out-of-space error was expected.)"

yum update -y

sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

yum clean all
%end


# Password policies
%anaconda
pwpolicy root --minlen=6 --minquality=1 --strict --nochanges --notempty
pwpolicy user --minlen=6 --minquality=1 --strict --nochanges --notempty
pwpolicy luks --minlen=6 --minquality=1 --strict --nochanges --notempty
%end
