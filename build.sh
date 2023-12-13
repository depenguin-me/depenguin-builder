#!/usr/bin/env bash

# log
# 2022-07-29: adding script to try automate builds, adapt for custom components
# 2022-07-31: adding extra rc.local, setting rc build script
# 2022-08-01: improvements for passwordless root, git version build script, accessip not in use
# 2022-08-02: switch to using git submodule for mfsbsd, drop git clone step for that repo
# 2022-08-04: improvements to script, clearing shellcheck errors
# 2022-08-05: adjustments based on github feedback
# 2022-08-12: bsdinstall customisations
# 2022-08-15: some general improvements
# 2022-08-23: include necessary packages in the mfsbsd image
#             add enable_ipv6.sh script
# 2023-05-27: update to FreeBSD-13.2 release
#             add image size as configurable parameter for MFSROOT_MAXSIZE
# 2023-12-13: configure for multiple releases
#

# this script must be run as root
if [ "$EUID" -ne 0 ]; then
	echo "Please run this script as root user"
	exit
fi

# 'set -eo pipefail' means we need to be careful with grep and zero search results
# because grep exits with an error code, causing the pipeline to fail, script exit
#
# a workaround is to enclose grep as follows, where e is search term:
#
# cmd | { grep e || :; } | cmd
#
set -eo pipefail

exit_error() {
	echo "$*" 1>&2
	exit 1;
}

usage() {
	cat <<-EOF
	Usage: $(basename "${BASH_SOURCE[0]}") [-hu] [-k /path/to/authorized_keys] version

	-h Show help
	-u Build with upload to remote host
	-k /path/to/authorized_keys (can safely ignore, another opportunity to copy
	   in SSH keys on image boot!)

	version (valid values are 13.2 or 14.0)
	EOF
}

# we must be on freebsd
what_os_am_i="$(uname)"
if [ "$what_os_am_i" != "FreeBSD" ]; then
	exit_error "Please run on FreeBSD only"
fi

# Defaults
UPLOAD="NO"

# get command line flags
while getopts huk: flag
do
	case "$flag" in
	h)
		usage
		exit 0
		;;
	u)
		UPLOAD="YES"
		;;
	k)
		AUTHKEYFILE="$(realpath "$OPTARG")"
		;;
	*)
		exit_error "$(usage)"
		;;
	esac
done
shift "$((OPTIND-1))"

# arg1 needs to be 13.2 or 14.0 currently
RELEASE="$1"

# Determine the release to use and set specific variables, or provide an error notice
case $RELEASE in
	13.2)
		FREEBSDISOSRC="https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/13.2/FreeBSD-13.2-RELEASE-amd64-disc1.iso.xz"
		# See https://www.freebsd.org/releases/13.2R/checksums/CHECKSUM.SHA256-FreeBSD-13.2-RELEASE-amd64.asc for SHA256 of ISO file, not iso.xz
		FREEBSDISOSHA256="b76ab084e339ee05f59be81354c8cb7dfadf9518e0548f88017d2759a910f17c"
		FREEBSDISOFILE="FreeBSD-13.2-RELEASE-amd64-disc1.iso"
		MYRELEASE="13.2-RELEASE"
		MYVERSION="13.2"
		;;
	14.0)
		FREEBSDISOSRC="https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.0/FreeBSD-14.0-RELEASE-amd64-disc1.iso.xz"
		# See https://www.freebsd.org/releases/14.0R/checksums/CHECKSUM.SHA256-FreeBSD-14.0-RELEASE-amd64.asc for SHA256 of ISO file, not iso.xz
		FREEBSDISOSHA256="7200214030125877561e70718781b435b703180c12575966ad1c7584a3e60dc6"
		FREEBSDISOFILE="FreeBSD-14.0-RELEASE-amd64-disc1.iso"
		MYRELEASE="14.0-RELEASE"
		MYVERSION="14.0"
		;;
	*)
		echo "Invalid version specified. Use 13.2 or 14.0."
		exit_error "$(usage)"
		;;
esac

# General Variables
BASEDIR="$PWD"
CDMOUNT="cd-rom"
CHECKMOUNTCD1="$(mount | { grep "$CDMOUNT" || :; } | awk '{print $1}')"
MFSBSDDIR="mfsbsd"
MYARCH="amd64"
OUTIMG="mfsbsd-$MYRELEASE-$MYARCH.img"    # not in use
OUTISO="mfsbsd-$MYRELEASE-$MYARCH.iso"    # in use
OUTIMAGESIZE="200m"
MYBASE="$BASEDIR/$CDMOUNT/usr/freebsd-dist"
MYCUSTOMDIR="$BASEDIR/customfiles"

# make sure we're in base directory
cd "$BASEDIR" || exit

# Check for available disk space (at least 10 GB required)
REQUIRED_SPACE_GB=10
AVAILABLE_SPACE_GB=$(df -k . | awk 'NR==2 {print int($4/(1024*1024))}')

if [ "$AVAILABLE_SPACE_GB" -lt "$REQUIRED_SPACE_GB" ]; then
	exit_error "Not enough disk space. At least $REQUIRED_SPACE_GB GB required."
fi

# check remote settings
if [ -f "$BASEDIR/settings.sh" ]; then
	# shellcheck source=customfiles/depenguin_settings.sh.sample
	source "$BASEDIR/settings.sh"
fi

if [ -z "$CFG_SSH_REMOTEHOST" ]; then
	CFG_SSH_REMOTEHOST=depenguin-me-builder
fi

# create directory if not existing
if [ ! -d "$BASEDIR/$CDMOUNT" ]; then
	echo "creating $CDMOUNT directory"
	mkdir -p "$BASEDIR/$CDMOUNT"
fi

# unmount any existing loopback mount
if [ -n "$CHECKMOUNTCD1" ]; then
	umount "$CHECKMOUNTCD1"
fi

# fetch the iso
if [ ! -f "$BASEDIR/$FREEBSDISOFILE" ]; then
	fetch -o - "$FREEBSDISOSRC" | unxz -T0 > "$BASEDIR/$FREEBSDISOFILE"
fi

# check iso checksum
if [ "$(sha256 -q "$BASEDIR/$FREEBSDISOFILE")" != "$FREEBSDISOSHA256" ]; then
	exit_error "Release checksum mismatch"
fi

# mount the iso file
if [ -f "$BASEDIR/$FREEBSDISOFILE" ]; then
	mount -t cd9660 /dev/"$(
	  /sbin/mdconfig -f "$FREEBSDISOFILE")" "$BASEDIR/$CDMOUNT"
fi

# change directory into mfabad submodule
cd "$MFSBSDDIR"

# clean any prior builds
make clean

# copy in ssh authorized key
if [ -n "$AUTHKEYFILE" ]; then
	cp -f "$AUTHKEYFILE" conf/authorized_keys
else
	: > conf/authorized_keys
fi

# copy in my custom configs
my_custom_configs=(
	boot.config
	hosts
	interfaces.conf
	loader.conf      # in use by dependguin.me build
	rc.conf          # in use by dependguin.me build
	rc.local         # in use by dependguin.me build
	resolv.conf
	ttys
)

for config_file in "${my_custom_configs[@]}"; do
	if [ -f "$MYCUSTOMDIR/$config_file" ]; then
		cp -f "$MYCUSTOMDIR/$config_file" \
		  "conf/$config_file"
	else
		rm -f "conf/$config_file"
	fi
done

# copy in bsdinstall customisations
custom_depenguin_installdir="customfiles/root"
mkdir -p "$custom_depenguin_installdir"

# use a bashism for substitution
VERSION_PREFIX="${MYVERSION//\./_}"

# setup correct files to copy in based on version
#
#  When updating for new version, copy 14_0_depenguin_bsdinstall.sh
#  to 14_1_depenguin_bsdinstall.sh and edit, and same for 14_0_INSTALLERCONFIG.sample
#
if [ -f "$MYCUSTOMDIR/${VERSION_PREFIX}_depenguin_bsdinstall.sh" ]; then
	cp -f "$MYCUSTOMDIR/${VERSION_PREFIX}_depenguin_bsdinstall.sh" "$MYCUSTOMDIR/depenguin_bsdinstall.sh"
	chmod +x "$MYCUSTOMDIR/depenguin_bsdinstall.sh"
else
	exit_error "Missing $MYCUSTOMDIR/${VERSION_PREFIX}_depenguin_bsdinstall.sh"
fi
if [ -f "$MYCUSTOMDIR/${VERSION_PREFIX}_INSTALLERCONFIG.sample" ]; then
	cp -f "$MYCUSTOMDIR/${VERSION_PREFIX}_INSTALLERCONFIG.sample" "$MYCUSTOMDIR/INSTALLERCONFIG.sample"
else
	exit_error "Missing $MYCUSTOMDIR/${VERSION_PREFIX}_INSTALLERCONFIG.sample"
fi

custom_bsdinstall_files=(
	depenguin_bsdinstall.sh       # in use by dependguin.me build
	depenguin_settings.sh.sample  # in use by dependguin.me build
	INSTALLERCONFIG.sample        # in use by dependguin.me build
	mfsbsd_clean.sh               # in use by dependguin.me build
	enable_ipv6.sh                # in use by dependguin.me build
)

for bsdinstall_file in "${custom_bsdinstall_files[@]}"; do
	if [ -f "$MYCUSTOMDIR/$bsdinstall_file" ]; then
		cp -f "$MYCUSTOMDIR/$bsdinstall_file" \
		  "$custom_depenguin_installdir/$bsdinstall_file"
	else
		rm -f "$custom_depenguin_installdir/$bsdinstall_file"
	fi
done

# add a list of packages to bake into the image
if [ -f "$MYCUSTOMDIR/depenguin_packages.txt" ]; then
	 cp -f "$MYCUSTOMDIR/depenguin_packages.txt" "$BASEDIR/mfsbsd/tools/packages"
else
	 exit_error "missing packages file"
fi

# delete old img (not in use)
rm -f "$OUTIMG"

# delete old iso (in use, but shouldn't exist unless rebuilding)
rm -f "$OUTISO"

# create iso
make iso BASE="$MYBASE" RELEASE="$MYRELEASE" ARCH="$MYARCH" ROOTPW_HASH="*" MFSROOT_MAXSIZE="$OUTIMAGESIZE"

# scp to distribution site
if [ "$UPLOAD" = "YES" ]; then
	#removed#
	#scp "$OUTISO" "$CFG_SSH_REMOTEHOST":"$CFG_SSH_REMOTEPATH"
	# new approach to deal with bad uploads, make sure host is configed in .ssh/config
	rsync -P -e ssh "$OUTISO" "$CFG_SSH_REMOTEHOST":"$CFG_SSH_REMOTEPATH"/"$1"
fi

# change directory
cd "$BASEDIR" || exit

# umount cdrom
CHECKMOUNTCD2="$(mount | { grep "$CDMOUNT" || :; } | awk '{ print $1 }')"
if [ -n "$CHECKMOUNTCD2" ]; then
	umount "$CHECKMOUNTCD2"
fi

# exit script
exit 0
