#!/bin/sh

# THIS SCRIPT WILL EAT YOUR DATA

if [ $# -lt 2 ]; then
	echo "Usage: $0 pool device..." 1>&2
	echo "Example: $0 zroot ada0 ada1" 1>&2
	exit 1
fi

pool="$1"
shift

echo "YOU ARE ABOUT TO DESTROY ZPOOL '$pool' AND PARTITIONS $*"
echo "THIS OPERATION MEANS DATA LOSS AND CANNOT BE UNDONE"
echo "Please type 'ACCEPTDATALOSS' and press enter to continue."
read -r ANSWER

if [ "$ANSWER" != "ACCEPTDATALOSS" ]; then
	echo "Cancelled. No datasets destroyed."
	exit 1
fi

zpool export -f "$pool"
zpool destroy -f "$pool"

for dev in "$@"; do
	# lazy
	for p in $(jot 9); do
		zpool labelclear -f "/dev/${dev}p${p}"
	done
	gpart destroy -F "$dev"
done

echo "DONE"
