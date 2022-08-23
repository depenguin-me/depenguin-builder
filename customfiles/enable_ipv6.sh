#!/bin/sh

service dhcpcd enable
service dhcpcd start
sysrc ip6addrctl_policy=ipv6_prefer
service ip6addrctl start