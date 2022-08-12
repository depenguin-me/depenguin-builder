#!/usr/bin/env bash
conf_hostname="your.hostname"
conf_interface="igb0"
conf_ipv4=""
conf_ipv6=""
conf_gateway=""
conf_nameserveripv4one=""
conf_nameserveripv4two=""
conf_nameserveripv6one=""
conf_nameserveripv6two=""
conf_username=""
conf_pubkeyurl=""
conf_disks="ada0 ada1"   # or ada0 | or nvme0n1 | or nvme0n1 nvme1n1
conf_disktype="mirror"   # or stripe for single disk
run_installer="0"        # set to 1 to enable installer
