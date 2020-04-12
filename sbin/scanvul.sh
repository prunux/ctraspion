#!/bin/bash
nmap -oX /tmp/$$_nmap.xml --script vuln $1
xsltproc /tmp/$$_nmap.xml -o ~localadmin/public_html/scans/$1_$$_nmap.html
chown localadmin:localadmin ~localadmin/public_html/scans/$1_$$_nmap.html

