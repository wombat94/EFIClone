#!/bin/bash
# EFI Partition System Restore
# (c) 2018 - Ted Howe
# tedhowe@burke-howe.com
# wombat94 on TonyMacx86 forums and GitHub.

# This script is designed to be run automatically by launchd each time your Hackintosh is booted.
# 
# The purpose of the script is to keep a clean copy of a bootable \EFI\ partition always accessible on
# the Mac boot partition that resides on the same physical disk as the EFI partition
# this is similar to a limited version of the Windows System Restore function in that there will 
# always be a clean copy of the last good bootable EFI partition.
#
# The script works by making a copy of the current bootable EFI partitoon to a user-defined location
# on the Boot Partition. (Defaulting to /EFISystemRestore/)
# Each time the system boots and launchd launches the script, the current boot EFI partition is mounted
# and the contents of that partition are compared to <destination>/EFICurrent/ and if they have changed, 
# then the contents of EFICurrent are backed up to a zip file with a date/time stamp in the filename
# and then the contents of the current EFI partition are copied to replace those in EFICurrent
# this way, there is a history of bootable EFI partition contents maintained on the associated boot
# partition.
#
# If a change to EFI causes it to become un-bootable, then a boot from an external USB disk into the macOS
# will allow the easy mounting of the EFI partiton and revert to last known bootable state by copying the 
# most recent contents of EFICurrent back to the EFI partition.
# 
# The restore process is a manual one for now, though I may work on either an script to automate it 
# or possibly a utility to allow tagging of backups with info and refresh/restore of the EFI 
# partition an easier process.

#Release Notes
# version 0.1beta1
# 3/1/2018
# Initial Release
#----------------------------------------------------------------------------------------------------------


#user variables

#Log File location. By default, this will write to the same directory where the cccEFIClone.sh script lives.
# you may edit it, but be sure the location will always exist and you have permissions to write to the location
# It appears that Carbon Copy Cloner runs the script in the root of the boot drive, so that is where the log will go 
# if you don't put in a literal path below.


EFIBackupLocation="/EFIsystemRestore/"
LOG_FILE="$EFIBackupLocation/EFISystemRestore.log"
#----- END OF USER VARIABLES
#----- THERE IS NO NEED TO EDIT BELOW THIS LINE
#----------------------------------------------

function writeTolog () {
	echo "[`date`] - ${*}" >> ${LOG_FILE} 
}

function getDiskNumber () {
	echo "$( diskutil info "$1" | grep 'Part of Whole' | rev | cut -d ' ' -f1 | rev )"
}

function getCoreStoragePhysicalDiskNumber () {
	echo "$( diskutil info "$1" | grep 'PV UUID' | rev | cut -d '(' -f1 | cut -d ')' -f2 | rev | cut -d 'k' -f2 | cut -d 's' -f1 )"
}

function getAPFSPhysicalDiskNumber () {
	echo "$( diskutil apfs list | grep -A 9 "Container $1" | grep "APFS Physical Store" | rev | cut -d ' ' -f 1 | cut -d 's' -f 2 | cut -d 'k' -f 1 )"
}

function getEFIVolume () {
	echo "$( diskutil list | grep "$1" | grep "EFI" | rev | cut -d ' ' -f 1 | rev )"	
}

function getDiskMountPoint () {
	echo "$( diskutil info "$1" | grep 'Mount Point' | rev | cut -d ':' -f 1 | rev | awk '{$1=$1;print}' )"
}

function getEFIDirectoryHash () {
	#echo "$( find -s . -type f \( ! -iname ".*" \) -print0 | xargs -0 shasum | cut -d ' ' -f 1 | shasum  )"
	echo "$( find -s . -not -path '*/\.*' -type f \( ! -iname ".*" \) -print0 | xargs -0 shasum | shasum )"
}

function logEFIDirectoryHashDetails () {
	#echo "$( find -s . -type f \( ! -iname ".*" \) -print0 | xargs -0 shasum | cut -d ' ' -f 1 | shasum  )"
	echo "$( find -s . -not -path '*/\.*' -type f \( ! -iname ".*" \) -print0 | xargs -0 shasum )" >> ${LOG_FILE}
}

function getSystemBootVolumeName () {
	echo "$( system_profiler SPSoftwareDataType | grep 'Boot Volume' | rev | cut -d ':' -f 1 | rev | awk '{$1=$1;print}' )"
}

function getCurrentBootEFIVolumeUUID () {
	echo "$( bdmesg | grep 'SelfDevicePath' | rev | cut -d ')' -f 2 | rev | cut -d ',' -f 3 )"
}

function getDeviceIDfromUUID () {
	echo "$( diskutil info "$1" | grep 'Device Identifier' | rev | cut -d ' ' -f 1 | rev )"
}

function getDiskIDfromUUID () {
	writeTolog "$1"
	echo "$( diskutil info "$1" | grep 'Device Identifier' | rev | cut -d ' ' -f 1 | rev )"
}

#begin logging
writeTolog "***** EFI SystemRestore_Backup script start"
writeTolog "working directory = $PWD" 
writeTolog "Running $0" 

efiBootPartitionUUID="$( getCurrentBootEFIVolumeUUID )"
writeTolog "efiBootPartitionUUID = $efiBootPartitionUUID"
efiBootPartionDisk="$( getDeviceIDfromUUID "$efiBootPartitionUUID" )"
writeTolog "efiBootPartitionDisk = $efiBootPartionDisk"

systemBootVolume="$( getSystemBootVolumeName )"
writeTolog "SystemBootVolumeName = $systemBootVolume"

writeTolog "EFIBackupLocation=$EFIBackupLocation"

sourceEFIPartitionDisk="$( getDiskIDfromUUID "$efiBootPartitionUUID" )"
writeTolog "sourceEFIPartitionDisk=$sourceEFIPartitionDisk"

diskutil mount /dev/$sourceEFIPartitionDisk
sourceEFIMountPoint="$( getDiskMountPoint "$sourceEFIPartitionDisk" )"

pushd "$sourceEFIMountPoint/"
sourceEFIHash="$( getEFIDirectoryHash "$sourceEFIMountPoint" )"
writeTolog "Source directory hash: $sourceEFIHash"
temp="$( logEFIDirectoryHashDetails "$sourceEFIMountPoint" )"
popd
pushd "$EFIBackupLocation/EFICurrent/"
destinationEFIHash="$( getEFIDirectoryHash "$EFIBackupLocation/EFICurrent/" )"
writeTolog "Destination directory hash: $destinationEFIHash"
temp="$( logEFIDirectoryHashDetails "$sourceEFIMountPoint" )"
popd

if [[ "$sourceEFIHash" == "$destinationEFIHash" ]]
then
	writeTolog "EFICurrent Backup matches the boot EFI partition. No new backup necessary"
else
	writeTolog "Latest EFICurrent backup differs from current EFI boot partition. "
	writeTolog "Backup previous EFICurrent Directory"
	timeStamp=$(date +%Y%m%d%H%M%S)
	writeTolog "timeStamp=$timeStamp"
	tar -jcvf /EFISystemRestore/EFI_$timeStamp.tar.bz2 /EFISystemRestore/EFICurrent/ >> ${LOG_FILE}
	writeTolog "Backup complete - run rsync to update EFICurrent"
	rsync -av --exclude=".*" --delete "$sourceEFIMountPoint/" "$EFIBackupLocation/EFICurrent/" >> ${LOG_FILE}
fi 
diskutil unmount /dev/$sourceEFIPartitionDisk 
writeTolog "EFI partition unmounted successfully."
writeTolog "exiting script."
exit 0
