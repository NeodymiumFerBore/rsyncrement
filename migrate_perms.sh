#!/bin/bash

# ntfs-3g 2017.3.23AR.3 integrated FUSE 28
# getfattr 2.4.48

# Get file crtime:
#   For an NTFS file "$file":
#   # https://unix.stackexchange.com/questions/87265/how-do-i-get-the-creation-date-of-a-file-on-an-ntfs-logical-volume
#       getfattr --only-values -n system.ntfs_crtime_be "$file" | perl -MPOSIX -0777 -ne '$t = unpack("Q>"); print ctime $t/10000000-11644473600'

#   For an ext4 file, on device /dev/sda2:
#       debugfs -R 'stat <'"$(stat -c %i "$file")"'>' /dev/sda2

# coreutils 8.31 now supports birthtime ("However, coreutils stat uses the statx() system call where available to retrieve the birth time only since version 8.31"):
#   https://unix.stackexchange.com/questions/91197/how-to-find-creation-date-of-file/92748

# Compile coreutils 8.32:
# # Add deb-src repositories, then
# cd /root
# apt install git build-essential
# apt build-dep coreutils
# git clone --depth 1 --branch v8.32 https://github.com/coreutils/coreutils.git
# cd coreutils
# ./bootstrap
# # If you do this as root (you shouldn't):
# export FORCE_UNSAFE_CONFIGURE=1
# ./configure
# make clean
# make -j4
# 
#   For a btfrs file, on device /dev/sdb2 (seconds since epoch):
#       /root/coreutils/src/stat -c %W "$file"


# Set ext4 file crtime, file inode as "$inode" on device /dev/sda2:
#   # UNMOUNT FILESYSTEM FIRST!!
#   debugfs -w -R 'set_inode_field <'"$inode"'> crtime 200001010101.11' /dev/sda2
#   # Drop vm cache so crtime update is reflected
#   echo 2 > /proc/sys/vm/drop_caches

# Set btrfs file otime, file inode as "$inode" on device /dev/sda3:
#

# Table mapping file extensions mapped to default permission
# Example: map[pdf] -> 640 ; map[sh] -> 750 ; etc.
# Not implemented: dangerous script stored for education purposes might then be executed by mistake and harm system
declare -A ext_perm_map

# Table mapping inode number to a creation time value (fetched from NTFS)
# Note: ext4 crtime attribute == btrfs otime attribute
declare -A inode_otime_map

# JAVASCRIPT
"""
// http://sunshine2k.blogspot.com/2014/08/where-does-116444736000000000-come-from.html
// https://www.epochconverter.com/ldap

function LdapToEpoch1() {
    var ldap = document.le1.ldap.value;
    var sec = Math.floor(ldap / 10000000);
    sec -= 11644473600;
    var datum = new Date(sec * 1000);
    var outputtext = "<b>Epoch/Unix time</b>: " + sec;
    outputtext += "<br/><b>GMT</b>: " + datum.epochConverterGMTString() + "<br/><b>Your time zone</b>: " + datum.epochConverterLocaleString();
    $('#resultle1').html(outputtext);
}
"""

# PYTHON
"""
# https://stackoverflow.com/questions/15649942/how-to-convert-epoch-time-with-nanoseconds-to-human-readable
def ldapToEpoch(t: int) {
    ldap = 132278759228785841
    sec = (ldap // 10000000) - 11644473600
    
    dt = datetime.fromtimestamp(sec)
    s = dt.strftime('%Y-%m-%d %H:%M:%S')
    s += '.' + str(int(sec % 1000000000)).zfill(9)
    s
}
"""


shopt -s globstar nullglob dotglob
for f in ./**; do
    echo "$f"
done



exit 0

