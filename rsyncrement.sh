#!/bin/bash

#---------------- CUSTOMIZE THIS -----------------------------

# What you want to backup
source="/home/user1/super cool folder"

# Where you want to back it up
destbase="/mnt/BACKUPS/"

# Backup suffix (default: YEAR-MONTH-DAY_HOUR-MIN-SEC)
timestamp="$(date +%Y-%m-%d_%H-%M-%S)"

#---------------- DO NOT TOUCH THIS --------------------------

#------------------------- Functions ----------------------------

function check_error() {
    for e in "${err[@]}"; do
        echo "$e"
    done
    [ "$1" == "fatal" ] && [ ${#err[@]} -gt 0 ] && exit 1
}

#---------------------- Variables ----------------------

rsync_opts=(
    '--info=progress2'
    '--recursive'
    '--links'
    '--times'
    '--perms'
    '--owner'
    '--group'
    '--acls'
    '--xattrs'
    '--devices'
    '--specials'
    '--delete-during'
    '--protect-args'
)
err=()

#------------------- Variables tweaking ----------------------

shopt -s extglob

# remove any trailing slash from destination
destbase="${destbase%%+(/)}"

# destination directory is the basename of $source
destdir="$(basename "$source").${timestamp}"

dest="${destbase}/${destdir}"

# We remove any trailing slash at the end of source, then we put one back on.
source="${source%%+(/)}/"

cat <<EOF
source = $source
dest   = $dest

EOF

#-------------------- Sanity checks ----------------------

# Source should exist
[ ! -d "$source" ]   && err+=("Error: source directory does not exist: '$source'")

# Destination base should exist
if   [ ! -d "$destbase" ]; then
    err+=("Error: destination base directory does not exist: '$destbase'")

# Destination base should be writable
elif [ ! -w "$destbase" ]; then
    err+=("Error: destination base directory is not writable: '$destbase'")
fi

# Destination dir should NOT exist
[ -d "$dest" ] && err+=("Error: destination directory already exists: '$dest'")

# Exit if any error occured
check_error fatal

#------------------- Looking for a base to increment from --------------------

# Find last backup
lastBackup="$(ls -1d "${destbase}/$(basename "${source}")".* 2>/dev/null | sort | sed '$!d')"

# If we find a previous backup, we link unchanged files to it
if [ ! -z "$lastBackup" ] && [ -d "$lastBackup" ]; then
    echo -e "Found a previous backup. New backup will be incremented from: '${lastBackup}/'\n"
    rsync_opts+=("--link-dest=${lastBackup}")
else
    echo -e "Could not find a previous backup. Doing full backup\n"
fi

#---------------------- RSYNC ---------------------------

touch "$dest"_IS_NOT_COMPLETE

rsync "${rsync_opts[@]}" "$source" "$dest" 2> "$dest"_error.log

rsync_retcode=$?
errlog_size="$(du -sb "$dest"_error.log | awk '{print $1}')"

[ $rsync_retcode -eq 0 ] && rm "$dest"_IS_NOT_COMPLETE || mv "$dest"_IS_NOT_COMPLETE "$dest"_ERRORS_OCCURED
[ $errlog_size -eq 0 ]   && rm "$dest"_error.log

exit $rsync_retcode
