#!/bin/bash
# SuperDuper! EFI Partition Clone Script
# (c) 2018 - Ted Howe
# tedhowe@burke-howe.com
# wombat94 on TonyMacx86 forums.

#Release Notes
#
# version 0.1beta1
# 2/22/2018
# Initial Release
#----------------------------------------------------------------------------------------------------------

# This script is designed to be a "post-flight" script run automatically by SD! at the end of a 
# clone task. It will copy the contents of the source drive's EFI partition to the destination drive's EFI 
# partition. It will COMPLETELY DELETE and replace all data on the destination EFI partition.

#!!! This script DOES delete data and therefore has the potential to cause unintended data loss.
# I have tried to think of any scenario that would cause unintended data loss, but as with all software, ther
# may be bugs and therefore there is a small risk.
# ONLY USE THIS SCRIPT IN THE MANNER DESCRIBED. I PROVIDE NO WARRANTY ON THE USE OF THIS SCRIPT
# PROCEED AT YOUR OWN RISK.

#user variables

#Log File location. By default, this will write to the same directory where the sdEFIClone.sh script lives.
# you may edit it, but be sure the location will always exist and you have permissions to write to the location
# It appears that SuperDuper! runs the script in the root of the boot drive, so that is where the log will go 
# if you don't put in a literal path below.
LOG_FILE="$PWD/sdEFIClone.log"

#test switch. The script is distributed with this switch set to "Y".
# the script will not delete or copy any data when this is set to Y
# in order to make the script take action, once you have verified that it can identify the right locations to 
# copy from and to on your system, change this variable to N
TEST_SWITCH=“Y”

#----- END OF USER VARIABLES
#----- THERE IS NO NEED TO EDIT BELOW THIS LINE
#----------------------------------------------

function writeTolog () {
	echo "[`date`] - ${*}" >> ${LOG_FILE} 
}

writeTolog "***** EFI Clone Script start"
writeTolog working directory = $PWD 
writeTolog "Running $0" 
writeTolog "1: Source Disk Name = $1"   # Source path
writeTolog "2: Source Mount Path = $2"   # Mounted disk image destination path
writeTolog "3: Destination Disk Name = $3"   # Exit status
writeTolog "4: Destination Mount Path = $4"  # Disk image file path
writeTolog "5: SuperDuper! Backup Script Used = $5"
writeTolog "6: Unused parameter 6 = $6"

osascript -e 'display notification "Starting EFI Clone Script" with title "SD! EFI Clone Scipt"'
#if [[ "$3" == "0" ]]
#then
#	writeTolog "SD! completed with success, the EFI Clone Script will run"
#else
#	writeTolog "SD! did not exit with success, the EFI Clone Script will not run"
#	exit 0
#fi

#if [[ "$4" == "" ]]
#then
#	writeTolog "SD! clone was not to a disk image. the EFI Clone Script will run"
#else
#	writeTolog "SD! Clone destination was a disk image file. The EFI Clone Script will not run"
#	exit 0
#fi


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

sourceVolume=$2

writeTolog sourceVolume = $sourceVolume 

sourceVolumeDisk="$( getDiskNumber "$sourceVolume" )"

writeTolog sourceVolumeDisk = $sourceVolumeDisk 

destinationVolume=$4

writeTolog destinationVolume = $destinationVolume 

destinationVolumeDisk="$( getDiskNumber "$destinationVolume" )"

writeTolog destinationVolumeDisk = $destinationVolumeDisk 
sourceDisk=$sourceVolumeDisk 
sourceEFIPartition="$( getEFIVolume "$sourceDisk" )"
#If we don't find an EFI partition on the disk that was identified by the volume path,
# then check to see if it is a coreStoreage volume and get the disk number from there
if [[ "$sourceEFIPartition" == "" ]]; then
    sourceDisk=""
	sourceDisk=disk"$( getCoreStoragePhysicalDiskNumber "$sourceVolumeDisk" )"
	if [[ "$sourceDisk" == "disk" ]]
	then
		sourceDisk=""
		sourceDisk=$sourceVolumeDisk 
	fi 
	sourceEFIPartition="$( getEFIVolume "$sourceDisk" )"
fi
#If we still don't have an EFI partition then look to see if the sourceVolumeDisk is an APFS 
# volume and find the physical disk
if [[ "$sourceEFIPartition" == "" ]]; then
    sourceDisk=""
	sourceDisk=disk"$( getAPFSPhysicalDiskNumber "$sourceVolumeDisk" )"
	sourceEFIPartition="$( getEFIVolume "$sourceDisk" )"
fi

writeTolog sourceEFIPartition = $sourceEFIPartition 

destinationDisk=$destinationVolumeDisk 
destinationEFIPartition="$( getEFIVolume "$destinationDisk" )"
#If we don't find an EFI partition on the disk that was identified by the volume path,
# then check to see if it is a coreStoreage volume and get the disk number from there
if [[ "$destinationEFIPartition" == "" ]]; then
	destinationDisk=""
	destinationDisk=disk"$( getCoreStoragePhysicalDiskNumber "$destinationVolumeDisk" )"
	if [[ "$destionationDisk" == "disk" ]]
	then
		destinationDisk=""
		destinationDisk=$destinationVolumeDisk
	fi
	destinationEFIPartition="$( getEFIVolume "$sourceDisk" )"
fi
#If we still don't have an EFI partition then look to see if the sourceVolumeDisk is an APFS 
# volume and find the physical disk
if [[ "$destinationEFIPartition" == "" ]]; then
	destinationDisk=""
	destinationDisk=disk"$( getAPFSPhysicalDiskNumber "$destinationVolumeDisk" )"
	destinationEFIPartition="$( getEFIVolume "$sourceDisk" )"
fi

writeTolog destinationEFIPartition = $destinationEFIPartition 

if [[ "$sourceEFIPartition" == "" ]]
then
	writeTolog "No SourceEFIPartition Found, script exiting."
	exit 0
fi 

if [[ "$destinationEFIPartition" == "" ]]
then
	writeTolog "No DestinationEFIPartition Found, script exiting."
	exit 0
fi

if [[ "$sourceEFIPartition" == "$destinationEFIPartition" ]]
then
	writeTolog "Source and Destination EFI Partitions are the same. Script exiting."
	exit 0
fi


diskutil mount /dev/$sourceEFIPartition
diskutil mount /dev/$destinationEFIPartition
writeTolog "drives Mounted"
sourceEFIMountPoint="$( getDiskMountPoint "$sourceEFIPartition" )"
writeTolog sourceEFIMountPoint = $sourceEFIMountPoint 

destinationEFIMountPoint="$( getDiskMountPoint "$destinationEFIPartition" )"
writeTolog destinationEFIMountPoint = $destinationEFIMountPoint 
if [[ "$TEST_SWITCH" == "Y" ]]
then
	writeTolog "********* Test simulation - file delete/copy would happen here. "
	writeTolog "File delete command calculated would have been..."
	writeTolog "rm -drfv "$destinationEFIMountPoint"/EFI"
	writeTolog "File copy command calculated would have been..."
	writeTolog "cp -R -apv "$sourceEFIMountPoint"/EFI "$destinationEFIMountPoint"/"
	writeTolog "********* Test Simulation - end of file delete/copy section."
else 
	writeTolog "Clearing all files from $destinationEFIMountPoint. Details follow..."
	writeTolog "--------------------------------------------------------------------"
	rm -drfv "$destinationEFIMountPoint/EFI" >> ${LOG_FILE} 
	writeTolog "--------------------------------------------------------------------"
	writeTolog "destination EFI partition cleared"
	writeTolog "Copying all files from $sourceEFIMountPoint/EFI to $destinationEFIMountPoint. Details follow..."
	writeTolog "--------------------------------------------------------------------"
	cp -R -apv "$sourceEFIMountPoint/EFI" "$destinationEFIMountPoint/" >> ${LOG_FILE} 
	writeTolog "--------------------------------------------------------------------"
	writeTolog "Contents of Source EFI Partition copied to Destination EFI Partition"
fi 
diskutil unmount /dev/$destinationEFIPartition
diskutil unmount /dev/$sourceEFIPartition
writeTolog "EFI Partitions Unmounted"
writeTolog "sdEFIClone.sh complete"
exit 0
