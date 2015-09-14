# About Flarewall

This script bridges the gap between CSF's IP temporary & permanent banning abilities and Cloudflare's IP blocking service. As CSF bans IP addresses, this script will send those IP addresses to Cloudflare for blocking. Similarly, as CSF removes temporary IP bans, this script will remove the offending IP addresses from Cloudflare's blocked list. It has been tested on CentOS 6.5 x86_64 with cPanel.

### Installation

Install mod_cloudflare and CSF.

* Download the script to your local machine.
* Open the script in a text editor such as Notepad++.
* Select all (CTRL+A) of the text and copy (CTRL+C) it to your clipboard.
* On your remote server, create a new file ( root@server [/] vi flarewall.sh ).
* Run the script (root@server [/] sh flarewall.sh).
* Re-run the script if API or email values were entered incorrectly during setup.
* Note: The uid:gid used in CSF must match the uid:gid for the *_REPORT scripts.
* Restart csf (root@server [/] csf -r) and lfd (root@server [/] service lfd restart) for changes to take effect.
