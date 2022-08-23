#!/bin/sh

killall dhclient

cat >/usr/local/etc/dhcpcd.conf <<EOF
duid
persistent
vendorclassid
option interface_mtu
option rapid_commit
slaac private
ipv6only
ipv6rs
nodhcp6
waitip 6
EOF

service dhcpcd enable
service dhcpcd restart
sysrc ip6addrctl_policy=ipv6_prefer
service ip6addrctl start
route delete default
