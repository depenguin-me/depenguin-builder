#!/bin/sh

set -e
# shellcheck disable=SC3040
set -o pipefail

exit_error() {
    echo "$*" 1>&2
    exit 1;
}

# read in variables
if [ -f depenguin_settings.sh ]; then
	# shellcheck source=customfiles/depenguin_settings.sh.sample
	. depenguin_settings.sh
else
	exit_error "Copy depenguin_settings.sh.sample to depenguin_settings.sh, edit to your needs, then run depenguin_bsdinstall.sh again"
fi

# check if template installerconfig exists
if [ ! -f INSTALLERCONFIG.sample ]; then
	exit_error "Missing INSTALLERCONFIG.sample. Please check location."
fi

# shellcheck disable=SC3003
# safe(r) separator for sed
sep=$'\001'

# change variables in INSTALLERCONFIG to our settings and save to INSTALLERCONFIG.active
< INSTALLERCONFIG.sample \
  sed "s${sep}%%hostname%%${sep}$conf_hostname${sep}g" | \
  sed "s${sep}%%interface%%${sep}$conf_interface${sep}g" | \
  sed "s${sep}%%ipv4%%${sep}$conf_ipv4${sep}g" | \
  sed "s${sep}%%ipv6%%${sep}$conf_ipv6${sep}g" | \
  sed "s${sep}%%gateway%%${sep}$conf_gateway${sep}g" | \
  sed "s${sep}%%nameserveripv4one%%${sep}$conf_nameserveripv4one${sep}g" | \
  sed "s${sep}%%nameserveripv4two%%${sep}$conf_nameserveripv4two${sep}g" | \
  sed "s${sep}%%nameserveripv6one%%${sep}$conf_nameserveripv6one${sep}g" | \
  sed "s${sep}%%nameserveripv6two%%${sep}$conf_nameserveripv6two${sep}g" | \
  sed "s${sep}%%username%%${sep}$conf_username${sep}g" | \
  sed "s${sep}%%pubkeyurl%%${sep}$conf_pubkeyurl${sep}g" | \
  sed "s${sep}%%disks%%${sep}$conf_disks${sep}g" | \
  sed "s${sep}%%disktype%%${sep}$conf_disktype${sep}g" \
  > INSTALLERCONFIG.active

# download source files
export DISTRIBUTIONS="kernel.txz base.txz"
export BSDINSTALL_DISTDIR="/tmp"
export BSDINSTALL_DISTSITE="https://download.freebsd.org/ftp/releases/amd64/13.5-RELEASE/"
bsdinstall distfetch

# run installer if enabled or output help text
if [ "$run_installer" -ne 0 ]; then
	bsdinstall script ./INSTALLERCONFIG.active
else
	echo "INFO: file INSTALLERCONFIG.active created"
	echo ""
	echo "WARN: run_installer is not enabled in depenguin_settings.sh"
	echo ""
	echo "Run installer manually as follows:"
	echo ""
	echo "  bsdinstall script ./INSTALLERCONFIG.active"
	echo ""
	echo "Or set run_installer=1 in depenguin_settings.sh"
	exit 0
fi

# end
