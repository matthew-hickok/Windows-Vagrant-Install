# Synopsis
Installs and Configures a Vagrant on a Windows host

# Installation
Requires WMF 5.0 as it uses Windows Package Management (OneGet)
Just dot-source the script" . .\Install-Vagrant.ps1

Then help Install-Vagrant -Detailed

# Notes
  * 1.8.5 should not require editing the plugins\synced_folders\rsync\helper.rb file -- still testing
  * There seem to be issues when using rsync with Vagrant and 64-bit Cygwin, for this reason it uses 32-bit
  * The install just sits at Ending Cygwin Install -- not sure if there is anything I can do about that
  *The weird sleep that I do is because the Cygwin installer is done in a way that POSH continues prior to the Cygwin install being finished
  

