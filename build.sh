#!/usr/bin/env bash

# log
# 2022-07-29: adding script to try automate builds, adapt for custom components
# 2022-07-31: adding extra rc.local, setting rc build script
# 2022-08-01: improvements for passwordless root, git version build script, accessip not in use
# 2022-08-02: switch to using git submodule for mfsbsd, drop git clone step for that repo
# 2022-08-04: improvements to script, clearing shellcheck errors
# 2022-08-05: adjustments based on github feedback
# 2022-08-12: bsdinstall customisations

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
	Usage: $(basename "${BASH_SOURCE[0]}") [-hu] [-k /path/to/authorized_keys] 
	
	-h Show help
	-u Build with upload to remote host
	-k /path/to/authorized_keys (can safely ignore, another opportunity to copy in SSH keys on image boot!)
	EOF
}

# we must be on freebsd
what_os_am_i="$(uname)"
if [ "${what_os_am_i}" != "FreeBSD" ]; then
    exit_error "Please run on FreeBSD only"
fi

UPLOAD="NO"
# get command line flags
while getopts huk: flag
do
    case "${flag}" in
        h) 
           usage
           exit 0
           ;;
        u) 
           UPLOAD="YES"
           ;;
        k) 
           AUTHKEYFILE="${OPTARG}"
           ;;
        *) 
           exit_error "$(usage)"
           ;;
    esac
done
shift "$((OPTIND-1))"

# Set default values if not set
# XXX: this might be unnecessary
if [ -z "${AUTHKEYFILE}" ]; then
    touch authorized_keys_in
    AUTHKEYFILE="authorized_keys_in"
fi

# General Variables
BASEDIR="$PWD"
CDMOUNT="cd-rom"
CHECKMOUNTCD1="$(mount | { grep "${CDMOUNT}" || :; } | awk '{print $1}')"
FREEBSDISOSRC="https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/13.1/FreeBSD-13.1-RELEASE-amd64-dvd1.iso"
FREEBSDISOFILE="FreeBSD-13.1-RELEASE-amd64-dvd1.iso"
MFSBSDDIR="mfsbsd"
MYRELEASE="13.1-RELEASE"
MYARCH="amd64"
OUTIMG="mfsbsd-${MYRELEASE}-${MYARCH}.img"    # not in use
OUTISO="mfsbsd-${MYRELEASE}-${MYARCH}.iso"    # in use
MYBASE="${BASEDIR}/${CDMOUNT}/usr/freebsd-dist"
MYCUSTOMDIR="${BASEDIR}/customfiles"

# make sure we're in base directory
cd "${BASEDIR}" || exit

# check remote settings
if [ -f "${BASEDIR}/settings.sh" ]; then
    # shellcheck source=/dev/null
    source "${BASEDIR}/settings.sh"
fi

if [ -z "${CFG_SSH_REMOTEHOST}" ]; then
    CFG_SSH_REMOTEHOST=depenguin-me
fi

# create directory if not existing
if [ ! -d "${BASEDIR}/${CDMOUNT}" ]; then
    echo "creating ${CDMOUNT} directory"
    mkdir -p "${BASEDIR}/${CDMOUNT}"
fi

# unmount any existing loopback mount
if [ -n "${CHECKMOUNTCD1}" ]; then
    umount "${CHECKMOUNTCD1}"
fi

# fetch the iso
if [ ! -f "${BASEDIR}/${FREEBSDISOFILE}" ]; then
    fetch "${FREEBSDISOSRC}" -o "${BASEDIR}/${FREEBSDISOFILE}"
fi

# mount the iso file
if [ -f "${BASEDIR}/${FREEBSDISOFILE}" ]; then
    mount -t cd9660 /dev/"$(/sbin/mdconfig -f "${FREEBSDISOFILE}")" "${BASEDIR}/${CDMOUNT}"
fi

# check for git submodule dir mfsbsd, change directory into it
if [ -d "${MFSBSDDIR}" ]; then
    cd "${MFSBSDDIR}" || exit
fi

# clean any prior builds
make clean

# copy in our custom configs
custom_auth_key="authorized_keys"
if [ -n "${AUTHKEYFILE}" ]; then
   cp -f "${BASEDIR}/${AUTHKEYFILE}" conf/"${custom_auth_key}"
fi

# in use by depenguin.me build
custom_rc_conf="rc.conf"
if [ -f "${MYCUSTOMDIR}/${custom_rc_conf}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_rc_conf}" conf/"${custom_rc_conf}"
fi

# in use by depenguin.me build
custom_rc_local="rc.local"
if [ -f "${MYCUSTOMDIR}/${custom_rc_local}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_rc_local}" conf/"${custom_rc_local}"
fi

custom_boot_config="boot.config"
if [ -f "${MYCUSTOMDIR}/${custom_boot_config}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_boot_config}" conf/"${custom_boot_config}"
fi

custom_hosts_file="hosts"
if [ -f "${MYCUSTOMDIR}/${custom_hosts_file}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_hosts_file}" conf/"${custom_hosts_file}"
fi

# in use by depenguin.me build
custom_loader_conf="loader.conf"
if [ -f "${MYCUSTOMDIR}/${custom_loader_conf}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_loader_conf}" conf/"${custom_loader_conf}"
fi

custom_interfaces_file="interfaces.conf"
if [ -f "${MYCUSTOMDIR}/${custom_interfaces_file}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_interfaces_file}" conf/"${custom_interfaces_file}"
fi

custom_resolv_conf="resolv.conf"
if [ -f "${MYCUSTOMDIR}/${custom_resolv_conf}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_resolv_conf}" conf/"${custom_resolv_conf}"
fi

custom_ttys_file="ttys"
if [ -f "${MYCUSTOMDIR}/${custom_ttys_file}" ]; then
    cp -f "${MYCUSTOMDIR}/${custom_ttys_file}" conf/"${custom_ttys_file}"
fi

# in use by depenguin.me build
# create customfiles/root directory if not exist
custom_depenguin_installdir="customfiles/root"
if [ ! -d "${custom_depenguin_installdir}" ]; then
    mkdir -p "${custom_depenguin_installdir}"
fi

# bsdinstall customisations
# in use by depenguin.me build
custom_depenguin_bsdinstall="depenguin_bsdinstall.sh"
if [ -f "${MYCUSTOMDIR}/${custom_depenguin_bsdinstall}" ] && \
   [ -d "${custom_depenguin_installdir}" ]; then
     cp -f "${MYCUSTOMDIR}/${custom_depenguin_bsdinstall}" \
       "${custom_depenguin_installdir}/${custom_depenguin_bsdinstall}"
fi

# in use by depenguin.me build
custom_depenguin_settings="depenguin_settings.sh.sample"
if [ -f "${MYCUSTOMDIR}/${custom_depenguin_settings}" ] && \
   [ -d "${custom_depenguin_installdir}" ]; then
     cp -f "${MYCUSTOMDIR}/${custom_depenguin_settings}" \
       "${custom_depenguin_installdir}/${custom_depenguin_settings}"
fi

# in use by depenguin.me build
custom_depenguin_installerconfig="INSTALLERCONFIG.sample"
if [ -f "${MYCUSTOMDIR}/${custom_depenguin_installerconfig}" ] && \
   [ -d "${custom_depenguin_installdir}" ]; then
     cp -f "${MYCUSTOMDIR}/${custom_depenguin_installerconfig}" \
       "${custom_depenguin_installdir}/${custom_depenguin_installerconfig}"
fi

# in use by depenguin.me build
custom_destroy_disks="mfsbsd_clean.sh"
if [ -f "${MYCUSTOMDIR}/${custom_destroy_disks}" ] && \
   [ -d "${custom_depenguin_installdir}" ]; then
     cp -f "${MYCUSTOMDIR}/${custom_destroy_disks}" \
       "${custom_depenguin_installdir}/${custom_destroy_disks}"
fi

# delete old img (not in use)
if [ -f "${OUTIMG}" ]; then
    rm "${OUTIMG}"
fi

# delete old iso (in use, but shouldn't exist unless rebuilding)
if [ -f "${OUTISO}" ]; then
    rm "${OUTISO}"
fi

# create iso
make iso BASE="${MYBASE}" RELEASE="${MYRELEASE}" ARCH="${MYARCH}" ROOTPW_HASH="*"

# scp to distribution site
if [ "$UPLOAD" = "YES" ]; then
    scp "${OUTISO}" "${CFG_SSH_REMOTEHOST}":"${CFG_SSH_REMOTEPATH}"
fi

# change directory
cd "${BASEDIR}" || exit

# umount cdrom
CHECKMOUNTCD2="$(mount | { grep "${CDMOUNT}" || :; } | awk '{print $1}')"
if [ -n "${CHECKMOUNTCD2}" ]; then
    umount "${CHECKMOUNTCD2}"
fi

# exit script
exit
