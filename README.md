# Router Spion (based on c't-Raspion project)

Turns a virtual Ubuntu 20.04 into a router to take a look at network traffic of smart home and IoT devices. All apps are reachable via web browser.

Idea and project bases on the [c't-Raspion project](https://github.com/ct-Open-Source/ctraspion) published by [german computer magazine c't](https://ct.de/).

Its initial release incorporates [Pi-hole](https://pi-hole.net/), [ntopng](https://www.ntop.org/products/traffic-analysis/ntop/), [Wireshark](https://www.wireshark.org/), [Shell In A Box](https://github.com/shellinabox/shellinabox) and [mitmproxy](https://mitmproxy.org/).

## Requirements

Uses an Ubuntu Server 20.04 (Focal). Wireshark(-gtk) will be displayed by [Broadwayd](https://developer.gnome.org/gtk3/stable/broadwayd.html) within a web browser window.

I use a direct attached Delock Network adapter to the Ubuntu 20.04: USB3.0 - 4x Gigabit Lan, [Datasheet](https://cdn.competec.ch/documents/9/5/956646/EN_Datasheet_datenblatt_62966.pdf).

## Installation

Install a freshly Ubuntu 20.04:
- Activate OpenSSH Server
- Create an inital user 'localadmin'


Install as user localadmin via:

```
wget -O ctraspion https://github.com/prunux/ctraspion/archive/master.zip
unzip ctraspion.zip
cd ctraspion
./install.sh
```

## Further reading

### Articles in c't (German)

In c't 1/2020:

[c’t-Raspion: Datenpetzen finden und bändigen](https://www.heise.de/ct/ausgabe/2020-1-c-t-Raspion-Datenpetzen-finden-und-baendigen-4611153.html)

[c't-Raspion: Projektseite – Foren weitere Hinweise](https://www.heise.de/ct/artikel/c-t-Raspion-Projektseite-4606645.html)
