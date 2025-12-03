#!/bin/sh
#
# This script should only be run on Hetzner AX102 servers
# after bsdinstall but before final rebooting

# set CPU frequency
echo "dev.cpu.0.freq=3000" >> /etc/sysctl.conf

# make sure we can boot without KVM console
sysrc -f /boot/loader.conf console=comconsole

# Enable AMD temperature sensor
sysrc -f /boot/loader.conf amdtemp_load=YES
