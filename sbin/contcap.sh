#!/bin/bash
nohup dumpcap -i br0 -g -q -w /home/localadmin/public_html/caps/$1.pcapng -a duration:$2 >> /home/localadmin/public_html/caps/$1.log 2>&1 &
