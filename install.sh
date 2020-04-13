#!/bin/bash

#
# Router Spion, a Ubuntu 20.04 all in one sniffer based on
# (c't-Raspion, a Raspberry Pi based all in one sniffer)
# for judging on IoT and smart home devices activity
#
# (c) 2019-2020 c't magazin, Germany, Hannover
#
# (c) 2020 prunux.ch, Plessl + Burkhardt GmbH, Niederrohrdorf, Switzerland

set -e

WD=$(pwd)
LOG=/var/log/spion.log
[[ -f .version ]] && source ./.version || VER=$(git rev-parse --short HEAD)
source ./.defaults
sudo touch $LOG
sudo chown $LOCALUSER:$LOCALGROUP $LOG

trap 'error_report $LINENO' ERR
error_report() {
    echo "Installation unfortunately failed in line $1."
}

echo "==> Setup of the Router-Spion ($VER)" | tee -a $LOG

echo "* Updating Base OS (Ubuntu) ..." | tee -a $LOG
sudo apt-get update >> $LOG 2>&1
sudo apt-get -y dist-upgrade >> $LOG 2>&1

echo "* Add help packages, update package lists" | tee -a $LOG
sudo apt-get install -y etckeeper  >> $LOG 2>&1

echo "* Prepare firewall rules, load modules" | tee -a $LOG
sudo iptables -t nat -F POSTROUTING >> $LOG 2>&1
sudo ip6tables -t nat -F POSTROUTING >> $LOG 2>&1
sudo iptables -t nat -F PREROUTING >> $LOG 2>&1
sudo ip6tables -t nat -F PREROUTING >> $LOG 2>&1
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE >> $LOG 2>&1
sudo ip6tables -t nat -A POSTROUTING -o eth0 -s $IPv6NET/64 -j MASQUERADE >> $LOG 2>&1
sudo iptables -A PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-ports 81 -i ens3 >> $LOG 2>&1
sudo ip6tables -A PREROUTING -t nat -p tcp --dport 80 -j REDIRECT --to-ports 81 -i ens3 >> $LOG 2>&1

echo "* Preconfigure packages..." | tee -a $LOG
sudo debconf-set-selections debconf/wireshark >> $LOG 2>&1
sudo debconf-set-selections debconf/iptables-persistent >> $LOG 2>&1
sudo apt-get install -y iptables-persistent >> $LOG 2>&1

echo "* Save firewall rules..." | tee -a $LOG
sudo netfilter-persistent save >> $LOG 2>&1

echo "* Installing packages ..." | tee -a $LOG
sudo apt-get install -y --no-install-recommends \
  lighttpd wireshark-gtk shellinabox mitmproxy bridge-utils ipv6calc hostapd nmap \
  xsltproc tcpreplay pwgen iptables-persistent libgtk-3-bin ntopng radvd >> $LOG 2>&1
cd /tmp
wget http://apt-stable.ntop.org/18.04/all/apt-ntop-stable.deb
sudo apt install ./apt-ntop-stable.deb
sudo apt-get install -y --no-install-recommends ntopng >> $LOG 2>&1

echo "* Basic software configuration ..." | tee -a $LOG
sudo usermod -a -G wireshark $LOCALUSER >> $LOG 2>&1
sudo usermod -a -G www-data $LOCALUSER >> $LOG 2>&1
sudo cp $WD/files/ntopng.conf /etc/ntopng.conf >> $LOG 2>&1
sudo sed -i "s/^-m=#IPv4NET#/-m=$IPv4NET/" /etc/ntopng.conf >> $LOG 2>&1
sudo sed -i "s/^-i=#INTERFACE#/-i=$INTERFACE/" /etc/ntopng.conf
sudo cp $WD/files/netplan-config.yaml /etc/netplan/00-router-spion.yaml
#sudo sed -i "s/^  address #IPv4HOST#/  address $IPv4HOST/" /etc/netplan/00-router-spion.yaml >> $LOG 2>&1
#sudo sed -i "s/^  address #IPv6HOST#/  address $IPv6HOST/" /etc/netplan/00-router-spion.yaml >> $LOG 2>&1
sudo cp $WD/files/ipforward.conf /etc/sysctl.d >> $LOG 2>&1
sudo cp $WD/files/hostname /etc/ >> $LOG 2>&1
sudo cp $WD/files/spion-sudo /etc/sudoers.d/ >> $LOG 2>&1
sudo cp $WD/files/radvd.conf /etc/ >> $LOG 2>&1
sudo sed -i "s/^  RDNSS #IPv6HOST#/  RDNSS $IPv6HOST/" /etc/radvd.conf >> $LOG 2>&1
sudo mkdir -p /root/.mitmproxy >> $LOG 2>&1
sudo cp $WD/files/mitmproxy-config.yaml /root/.mitmproxy >> $LOG 2>&1
mkdir -p /home/$LOCALUSER/.config/wireshark >> $LOG 2>&1
cp $WD/files/wireshark_config /home/$LOCALUSER/.config/wireshark >> $LOG 2>&1
sudo sed -i "s/#LOCALUSER#/$LOCALUSER/" /home/$LOCALUSER/.config/wireshark >> $LOG 2>&1
cp $WD/files/wireshark_preferences /home/$LOCALUSER/.config/wireshark/preferences >> $LOG 2>&1
sudo sed -i "s/#LOCALUSER#/$LOCALUSER/" /home/$LOCALUSER/.config/wireshark/preferences >> $LOG 2>&1
sudo sed -i "s/#INTERFACE#/$INTERFACE/" /home/$LOCALUSER/.config/wireshark/preferences >> $LOG 2>&1
sudo cp $WD/files/gtk-settings.ini /etc/gtk-3.0 >> $LOG 2>&1
sudo cp -f $WD/files/shellinabox /etc/default >> $LOG 2>&1
cd /usr/lib/python3/dist-packages/mitmproxy/addons/onboardingapp/static >> $LOG 2>&1
sudo ln -sf /usr/share/fonts-font-awesome fontawesome >> $LOG 2>&1

echo "* Prepare systemd units ..." | tee -a $LOG
sudo cp $WD/files/mitmweb.service /etc/systemd/system >> $LOG 2>&1
sudo cp $WD/files/broadwayd.service /etc/systemd/system >> $LOG 2>&1
sudo cp $WD/files/wireshark.service /etc/systemd/system >> $LOG 2>&1
sudo sed -i "s/#LOCALUSER#/$LOCALUSER/" /etc/systemd/sytem/wireshark.service >> $LOG 2>&1
sudo sed -i "s/#INTERFACE#/$INTERFACE/" /etc/systemd/sytem/wireshark.service >> $LOG 2>&1
sudo systemctl enable mitmweb >> $LOG 2>&1
sudo systemctl unmask hostapd >> $LOG 2>&1
sudo systemctl enable radvd >> $LOG 2>&1
sudo systemctl enable broadwayd >> $LOG 2>&1
sudo systemctl enable wireshark >> $LOG 2>&1

echo "* Add Web Interface ..." | tee -a $LOG
cd /etc/lighttpd/conf-enabled >> $LOG 2>&1
sudo ln -sf ../conf-available/10-userdir.conf 10-userdir.conf >> $LOG 2>&1
sudo ln -sf ../conf-available/10-proxy.conf 10-proxy.conf >> $LOG 2>&1
sudo cp $WD/files/10-dir-listing.conf . >> $LOG 2>&1
sudo -s <<HERE
echo '\$SERVER["socket"] == ":81" {
        server.document-root = "/home/#LOCALUSER#/public_html"
        dir-listing.encoding = "utf-8"
        \$HTTP["url"] =~ "^/caps(\$|/)" {
            dir-listing.activate = "enable"
        }
        \$HTTP["url"] =~ "^/scans(\$|/)" {
           dir-listing.activate = "enable"
        }
        \$HTTP["url"] =~ "^/admin" {
                proxy.server = ( "" => (( "host" => "'$IPv4HOST'", "port" => "80")) )
        }
}' > /etc/lighttpd/conf-enabled/20-extport.conf
HERE
sudo sed -i "s/#LOCALUSER#/$LOCALUSER/" /etc/lighttpd/conf-enabled/20-extport.conf >> $LOG 2>&1
sudo mkdir -p /home/$LOCALUSER/public_html/scans >> $LOG 2>&1
sudo mkdir -p /home/$LOCALUSER/public_html/caps >> $LOG 2>&1
sudo cp $WD/files/*.png /home/$LOCALUSER/public_html >> $LOG 2>&1
sudo cp $WD/files/*.php /home/$LOCALUSER/public_html >> $LOG 2>&1
sudo cp $WD/files/*.css /home/$LOCALUSER/public_html >> $LOG 2>&1
sudo cp $WD/files/*.js /home/$LOCALUSER/public_html >> $LOG 2>&1
sudo cp $WD/files/*.ico /home/$LOCALUSER/public_html >> $LOG 2>&1
sudo chown -Rh $LOCALUSER: /home/$LOCALUSER/public_html
sudo chmod g+s /home/$LOCALUSER/public_html/caps >> $LOG 2>&1
sudo chmod 777 /home/$LOCALUSER/public_html/caps >> $LOG 2>&1
sudo chgrp www-data /home/$LOCALUSER/public_html/caps >> $LOG 2>&1

echo "* Installation of Pi-hole ..." | tee -a $LOG
if ! id pihole >/dev/null 2>&1; then
    sudo adduser --no-create-home --disabled-login --disabled-password --shell /usr/sbin/nologin --gecos "" pihole >> $LOG 2>&1
fi
sudo mkdir -p /etc/pihole >> $LOG 2>&1
sudo chown pihole:pihole /etc/pihole >> $LOG 2>&1
sudo cp $WD/files/setupVars.conf /etc/pihole >> $LOG 2>&1
sudo sed -i "s/IPV4_ADDRESS=#IPv4HOST#/IPV4_ADDRESS=$IPv4HOST/" /etc/pihole/setupVars.conf >> $LOG 2>&1
sudo sed -i "s/IPV6_ADDRESS=#IPv6HOST#/IPV6_ADDRESS=$IPv6HOST/" /etc/pihole/setupVars.conf >> $LOG 2>&1
sudo sed -i "s/DHCP_ROUTER=#IPv4HOST#/DHCP_ROUTER=$IPv4HOST/" /etc/pihole/setupVars.conf >> $LOG 2>&1
sudo sed -i "s/DHCP_START=#DHCPv4START#/DHCP_START=$DHCPv4START/" /etc/pihole/setupVars.conf >> $LOG 2>&1
sudo sed -i "s/DHCP_END=#DHCPv4END#/DHCP_END=$DHCPv4END/" /etc/pihole/setupVars.conf >> $LOG 2>&1
sudo sed -i "s/PIHOLE_INTERFACE=#INTERFACE#/PIHOLE_INTERFACE=$INTERFACE/" /etc/pihole/setupVars.conf >> $LOG 2>&1
sudo apt-get update >> $LOG 2>&1
sudo -s <<HERE
curl -sSL https://install.pi-hole.net | bash /dev/stdin --unattended >> $LOG 2>&1
HERE
sudo chattr -f -i /etc/init.d/pihole-FTL >> $LOG 2>&1
sudo cp $WD/files/pihole-FTL /etc/init.d/ >> $LOG 2>&1
sudo chattr -f +i /etc/init.d/pihole-FTL >> $LOG 2>&1
sudo systemctl daemon-reload >> $LOG 2>&1
sudo systemctl restart pihole-FTL >> $LOG 2>&1
sudo pihole -f restartdns >> $LOG 2>&1
# sudo cp $WD/files/hosts /etc/ >> $LOG 2>&1

echo "==> Installation des c't-Raspion erfolgreich abgeschlossen." | tee -a $LOG
echo ""
echo "Das Passwort für das WLAN zur Beobachtung lautet: $PW"
echo "Notieren Sie dieses bitte, ändern Sie auch gleich das Passwort"
echo "für den Benutzer pi (mit passwd)."
echo ""
echo "Starten Sie Ihren Raspberry Pi jetzt neu: sudo reboot now"


