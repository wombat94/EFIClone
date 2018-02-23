# EFIClone

EFIClone.sh is a macOS bash shell script for Hackintosh machines that is designed to integrate with either Carbon Copy Cloner or SuperDuper! - the two most popular macOS disk cloning utilities.

CCC and SD! both will automatically create bootable clones on real Macintoshes in a single step. Though modern Macs support the EFI booting in order to maintain compatibility with running non-Apple operating system on their hardware, they do NOT need the EFI partition in order to boot MacOS. Because of this, the disk clone utilities do not copy the contents of the secondary EFI partition from one drive to another when doing their job.

This is where EFIClone comes in.

Both CCC and SD! have the ability to configure a "post flight" script that will be launched when the main clone job has been completed.

Both programs pass details of the source and destination drives that were used in the clone job, and from this the script is able to find the associated EFI partitions and automatically copy the contents of the critical EFI folder from the source drive to the destination drive as well.

The script provides extensive logging, has a "test" mode that will log what it WOULD have done but will not modify any data, and sends a notification to the macOS notification center with the results of the run.

When configured in your CCC or SD! clone job, EFIClone will allow you to do a single-step clone from your current hackintosh drive to a truly bootable backup drive with no other steps required.

---------------------

SCRIPT CONFIGURATION

There are currently only two user confiruation settings. 

Since this is a script file, they have to be manually edited with a text editor.

The most important setting is the TEST_SWITCH.

TEST_SWITCH="Y" (Default on a new install is "Y")

  - a value of "Y" tells the script to only test it's run - no modification of data will happen
  - a value other than "Y" allows the script to run in normal mode - it will delete the contents of the destination EFI partition and
      replace them with the contents of the source EFI partition.

This setting tells the script whether to run in Test Mode. In Test Mode all parsing of the script input will take place, the EFI partitions will be mounted, the data on the source and destination partitions will be verified and all activity will be logged, but NO DATA WILL BE MODIFIED. This is a safety measure. Please run the script with TEST_SWITCH="Y" at least once and review the log file to see the results before attemtping to let the script modify anything. I use this script for myself and have no problems with it but is is brand new (beta) and it WILL delete the contents of what it believe is the EFI partiton on the destination drive. It is possible that something could be screwed up and I don't want to delete the wrong data. Regardless of what the test shows, I have to add this disclaimer: I AM NOT RESPONSIBLE FOR DATA LOSS ON YOUR SYSTEM. PLEASE ENSURE YOU HAVE A WORKING BACKUP BEFORE YOU ATTEMPT TO USE THIS SCRIPT. I HAVE DONE EVERYTHING I CAN TO PREVENT DATA LOSS, BUT THERE MAY BE BUGS IN THIS CODE. I PROVIDE NO WARRANTY ON THE SOFTWARE. USE AT YOUR OWN RISK.

The only other setting is the path where the log file will be written out.

LOG_FILE="$PWD/EFIClone.log" (Default is the path to the working directory and a file named EFIClone.log)

There is no absolute need to change this setting, but if you want to force the log to be written elsewhere, you can put the full path in this setting.

From what I can tell, both Carbon Copy Cloner and SuperDuper! run the script with a woking directory of the root of the boot drive "/". That is where it writes the log on my system every time. If you can't find the log, just search for it in SpotLight.


INSTALLATION
------------------------------------

There really is nothing to "install". This is a simple shell script that relies ONLY on native macOS command line utilities to perform all of its functions.

Download the file and place it anywhere on your system that is accessible.

CLONE UTILITY CONFIGURATION
------------------------------------

The configuration of both utilities is similar, but not exact. See the following sections for each.

Carbon Copy Cloner

1. Create a Clone task as you normally would, defining the Source and Destination partitions.
2. Click on the Advance Settings button, just below the Source partition.
3. The advanced settings pane will open. If necessary scroll down until you can see the section labeled "AFTER COPYING FILES" and click on the folder icon next to "Run a Shell Script:"
4. Use the file dialog to select EFIClone.sh from the folder where you placed it after downloading.
5. After you have selected it, your task should look like this - with the script name "EFIClone.sh" showing next to the "Run a Shell Script:" line. If you want to you can click on the "eye" icon to see a read-only version of the script. If you need to change the script (or remove it completely) you can click on the "X" icon to deatch the script from your CCC Task.

SuperDuper!

1. Choose your Source and Destination partitions in the "Copy" and " to " drop down menus.
2. Click on the "Options..." button
3. This will display the "General" options tab. Click on "Advanced" to show the Advanced options.
4. Check the box that says "Run shell script after copy completes" and click on "Choose..."
5. Use the file dialog to select EFIClone.sh from the folder where you placed it after downloading.
6. After you have selected it, the dialog should show the path to the script.

Please report any bugs. Feel free to open issues for enhancements you would like to see.

