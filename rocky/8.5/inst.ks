install
cdrom
lang en_US.UTF-8
keyboard us
network --bootproto=dhcp
rootpw vagrant
firewall --disabled
selinux --permissive
timezone UTC
bootloader --location=mbr
text
skipx
zerombr
clearpart --all --initlabel
autopart
auth --enableshadow --passalgo=sha512 --kickstart
firstboot --disabled
eula --agreed
services --enabled=NetworkManager,sshd
user --name=vagrant --plaintext --password=vagrant --groups=wheel
reboot

%packages --ignoremissing --excludedocs
@Base
@Core
@Development Tools
openssh-clients
sudo
openssl-devel
readline-devel
zlib-devel
kernel-headers
kernel-devel
net-tools
vim
wget
curl
rsync

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

%post
yum update -y

# update root certs
wget -O/tmp/ca-bundle.crt https://curl.haxx.se/ca/cacert.pem

openssl x509 -text -in /tmp/ca-bundle.crt > /dev/null && mv /tmp/ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt

# sudo
yum install -y sudo
echo "vagrant        ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers.d/vagrant
sed -i "s/^.*requiretty/#Defaults requiretty/" /etc/sudoers

yum clean all
%end