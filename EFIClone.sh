#!/bin/bash
# EFI Partition Clone Script
# (c) 2018 - Ted Howe
# tedhowe@burke-howe.com
# wombat94 on TonyMacx86 forums and GitHub.

#Release Notes
#
# version 0.1beta2
# 2/23/2018
# Clean up and combine.
# Combined the two versions of the script into a single script that detects whether it was called from
# Carbon Copy Cloner or SuperDuper! and behaves accordingly in the setup. 
#----------------------------------------------------------------------------------------------------------
# version 0.1beta1
# 2/22/2018
# Initial Release
#----------------------------------------------------------------------------------------------------------

# This script is designed to be a "post-flight" script run automatically by CCC at the end of a 
# clone task. It will copy the contents of the source drive's EFI partition to the destination drive's EFI 
# partition. It will COMPLETELY DELETE and replace all data on the destination EFI partition.

#!!! This script DOES delete data and therefore has the potential to cause unintended data loss.
# I have tried to think of any scenario that would cause unintended data loss, but as with all software, ther
# may be bugs and therefore there is a small risk.
# ONLY USE THIS SCRIPT IN THE MANNER DESCRIBED. I PROVIDE NO WARRANTY ON THE USE OF THIS SCRIPT
# PROCEED AT YOUR OWN RISK.

#user variables

#Log File location. By default, this will write to the same directory where the cccEFIClone.sh script lives.
# you may edit it, but be sure the location will always exist and you have permissions to write to the location
# It appears that Carbon Copy Cloner runs the script in the root of the boot drive, so that is where the log will go 
# if you don't put in a literal path below.
LOG_FILE="$PWD/EFIClone.log"

#test switch. The script is distributed with this switch set to "Y".
# the script will not delete or copy any data when this is set to Y
# in order to make the script take action, once you have verified that it can identify the right locations to 
# copy from and to on your system, change this variable to N
TEST_SWITCH="Y"

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
	echo "$( find -s . -type f -print0 | xargs -0 shasum | cut -d ' ' -f 1 | shasum  )"
}

#begin logging
writeTolog "***** EFI Clone Script start"
writeTolog "working directory = $PWD" 
writeTolog "Running $0" 

#determine which disk clone application called the script (based on number of parameters)
# - log details
# - set up initial parameters
# - if possible do calling app-specific sanity checks in order to exit without taking action if necessary
if [[ "$#" == "4" ]]
then
	#log inputs to script
	writeTolog "Called From Carbon Copy Cloner"
	writeTolog "1: Source Path = $1"   # Source path
	writeTolog "2: Destination Path = $2"   # Mounted disk image destination path
	writeTolog "3: CCC Exit Status = $3"   # Exit status
	writeTolog "4: Disk image file path = $4"  # Disk image file path

	#sanity checks to determine whether to run
	if [[ "$3" == "0" ]]
	then
		writeTolog "CCC completed with success, the EFI Clone Script will run"
	else
		writeTolog "CCC did not exit with success, the EFI Clone Script will not run"
		osascript -e 'display notification "CCC Task failed, EFI Clone Script did not run" with title "EFI Clone Script"'
		exit 0
	fi

	if [[ "$4" == "" ]]
	then
		writeTolog "CCC clone was not to a disk image. the EFI Clone Script will run"
	else
		writeTolog "CCC Clone destination was a disk image file. The EFI Clone Script will not run"
		osascript -e 'display notification "CCC Clone destination was a disk image. Clone script did not run." with title "EFI Clone Script"'
		exit 0
	fi
 
	#set source and destination from variables passed in
	sourceVolume=$1
	destinationVolume=$2
else	
	if [[ "$#" == "6" ]]
	then 
		#log inputs to script
		writeTolog "Called From SuperDuper!"
		writeTolog "1: Source Disk Name = $1"   
		writeTolog "2: Source Mount Path = $2"   
		writeTolog "3: Destination Disk Name = $3"   
		writeTolog "4: Destination Mount Path = $4"  
		writeTolog "5: SuperDuper! Backup Script Used = $5"
		writeTolog "6: Unused parameter 6 = $6"
		
		#set source and destination from variables passed in
		sourceVolume=$2
		destinationVolume=$4	
	else
		#an unknown number of parameters have been passed in. log that fact and then exit
		writeTolog "$# parameters were passed in. This is an unsupported number of parameters. Exiting now"
		echo "$# parameters were passed in. This is an unsupported number of parameters. Exiting now"
		osascript -e 'display notification "Unsupported set of parameters passed in. EFI Clone script did not run!" with title "EFI Clone Script"'
		exit 0
	fi 
fi

writeTolog sourceVolume = $sourceVolume 

sourceVolumeDisk="$( getDiskNumber "$sourceVolume" )"

writeTolog sourceVolumeDisk = $sourceVolumeDisk 

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
	osascript -e 'display notification "No source EFI Partition found. EFI Clone Script did not run!." with title "EFI Clone Script"'
	exit 0
fi 

if [[ "$destinationEFIPartition" == "" ]]
then
	writeTolog "No DestinationEFIPartition Found, script exiting."
	osascript -e 'display notification "No destination EFI Partition found. EFI Clone Script did not run!." with title "EFI Clone Script"'
	exit 0
fi

if [[ "$sourceEFIPartition" == "$destinationEFIPartition" ]]
then
	writeTolog "Source and Destination EFI Partitions are the same. Script exiting."
	osascript -e 'display notification "Source and Destination EFI partitions are the same. EFI Clone Script did not run!." with title "EFI Clone Script"'
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
writeTolog "Compare the checksums of the EFI directories on the source and destination partitions"
writeTolog "-------------------------------------------------------------------------------------"
pushd "$sourceEFIMountPoint/EFI"
sourceEFIHash="$( getEFIDirectoryHash "$sourceEFIMountPoint/EFI" )"
popd
pushd "$destinationEFIMountPoint/EFI"
destinationEFIHash="$( getEFIDirectoryHash "$destinationEFIMountPoint/EFI" )"
popd
writeTolog "Source directory hash: $sourceEFIHash"
writeTolog "Destination directory hash: $destinationEFIHash"
if [[ "$sourceEFIHash" == "$destinationEFIHash" ]]
then
	writeTolog "Directory hashes match! file copy successful"
else
	writeTolog "Directory hashes differ! file copy unsuccessful"
fi 
writeTolog "-------------------------------------------------------------------------------------"
diskutil unmount /dev/$destinationEFIPartition
diskutil unmount /dev/$sourceEFIPartition
writeTolog "EFI Partitions Unmounted"
writeTolog "cccEFIClone.sh complete"
if [[ "$sourceEFIHash" == "$destinationEFIHash" ]]
then
	osascript -e 'display notification "EFI Clone Script completed successfully." with title "EFI Clone Script"'
else
	osascript -e 'display notification "EFI Clone failed - destionation data did not match source after copy." with title "EFI Clone Scipt"'
fi 


exit 0
