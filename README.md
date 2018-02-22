# EFIClone
macOS Shell Scripts to clone the EFI partition automatically from either Carbon Copy Cloner or SuperDuper! when run on a Hackintosh

It is a standard bash script and it uses only standard macOS installed commands.

You configure this script as a "post flight" script in your CCC Task. To access this, you click on "Advanced Settings" and scroll down to the "AFTER COPYING FILES" section. The first setting in that section is "Run a Shell Script:". Click on the folder and choose the cccEFIClone.sh file.

That is all you need to do within CCC.

Within the script there are just two settings currently that are user editable - these are both at the top of the script.

First is the LOG_FILE setting. This is the complete path to where the log will be written (including filename).

This does not HAVE to be edited but you can if you want. The default is to write the log to the working directory where the script is running from. On my system, at least, it appears that the working directory for the script is the root of the boot volume. If you want it to go elsewhere, feel free to change this setting.

The second setting is called "TEST_SWITCH". This is a control switch so that you can run the script without making any data changes to your disks. It will parse and set all variables and log those settings to the log file so you can review them before turning the script loose to be run in anger. The script will always be distributed with this switch set to "Y". Any other setting that you change it to will mean that the script will run and will delete previous data in the Destination EFI partition and replace it with the copy from the Source EFI partition.

PLESAE BE SURE TO HAVE ANOTHER WORKING BACKUP OF YOUR SYSTEM BEFORE CHANGING THIS SETTING AND ALLOWING THE SCRIPT TO MODIFY YOUR DATA.

Standard disclaimers apply here... this script is provided without warranty and I take no responsibility for data loss you may incur. If it is configured to run through CCC it should only EVER modify data on a fresh backup volume, so it should not put your primary system in danger, but I've been a software developer for 20 years, so I know that what it "SHOULD" do and what it might do out in the wild are not always one and the same. Be careful. Be sure to test your backup to see that it works.

Now... having all of that out of the way, here is a description of what the script does.

At the end of each CCC clone task run, if you have a script configured, CCC launches the script and passes four parameters in to the script:

1. The source volume path that was cloned
2. The destination volume path that received the clone
3. An exit code indicating whether the CCC clone job completed successfully or not
4. If the destination was a disk image (rather than an actual disk partition), the path and name of the image file is passed here, otherwise this parameter is blank.

First, my script is instantiated, it first checks to see if the CCC clone task completed successfully. If it did not, the script exits
Second, it checks the fourth parameter to see if it is populated. If there is ANYTHING in this parameter, that means the destination was a disk image - and the idea of copying to an EFI partition on an image doesn't make sense, so it exits
Having passed those two initial checks, the script then uses diskutil info to get the disk that the partition corresponding to the volume path resides on for both the source and destination volumes
It then tries to find an EFI partition on each of these disks in turn. If a simple check for an EFI partition on that disk number returns nothing, it will first check to see if the disk is a CoreStorage volume and then find the physical disk that the CoreStorage volume resides on and check THAT volume for an EFI partition.
If the check for CoreStorage still does not return an EFI partition, it falls back to check for an APFS volume and the physical disk that THAT resides on.
If we still are without a valid EFI partition for either source or destination after checking for physical disk, coreStorage and APFS, then we cannot proceed with the clone and the script exits.
Finally, if EFI partitions were found for both source and destination partitions, we check to be sure that they are not both on the same disk. If that is the case, then something went very wrong and we can't clone onto the same drive itself, so the script will exit.
Now with all of the preliminary setup out of the way, we are finally ready to take action. The script will then:

Mount the source EFI partition
Mount the destination EFI partition
Resolve the Mount Point of both of the above mounted partitions to ensure we are copying from and to the right locations. As long as they are mounted in order the source should be EFI and the destination should be EFI 1, but it is possible other EFI partitions were mounted already or that the Destination might still be mounted from previous user actions and it could be at the EFI mount point. The delete and copy commands are only ever executed using these system-resolved mount points - not the volume names.
After the drives are mounted, the destination drive is cleared - a recursive rm command is issued to totally wipe the drive
Next all files on the source are copied over to the destination drive
Both of the above commands are run in "verbose" mode and all output is sent to the log file so there is a complete record of the actions of the script
Finally, after the script is complete, both source and destination are unmounted and the script exits

So that is it in a nutshell.

This is definitely a v0.1 beta. Most of this is very simple so it will not evolve too much, but there are a few things I already plan to work on...

1. The logic to find the physical disk # or check the two virtual storage volume types for their physical disk works, but it is ugly. I do plan to refactor this to clean it up
2. I don't really have any error handling or reporting. There are only two commands that take any physical action on your system and they are both pretty solid, but I would like to add/improve logging so that I can find issues as people start using it.
3. There are already two use cases I can think of that I want to trap for and make additional exit points:
If there happens to be more than one EFI partition on a physical disk, I want to detect that and disallow things to proceed. I don't want to guess at which EFI partition should be used if either of the drives happen to have this.
I am considering doing a disk free space check to make sure there is room. I believe the EFI partition is a standard size dictated by the EFI spec, but that doesn't mean there couldn't be a drive that is "masquerading" as a true EFI volume.
​
I also have found that there is a way to raise a notification to the Notification Center from a shell script, so I am going to look into that to provide some affirmative feedback about the results, rather than relying on the user to review the log.

Please let me know how this goes and feel free to ask any questions.

One area I am particularly interested in is testing with an APFS volume (either as a source or destination). I'm not running High Sierra on my hackintoshes yet - only on my real MacBook Pro, so I was able to code and test the detection logic, but can't test the overall script on a hack.

Enjoy!

I definitely will move this out to the Post Install/General forum, but want to have the script setup on GitHub first, and I won't get to that until this weekend.

Ted