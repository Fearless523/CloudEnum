# CloudEnum
Something I've done to learn a bit more about Cloud Enumeration, and shell scripting.

This may or may not work, as I don't have anything to test it on yet. I will be creating a free AWS account to do this in the future. Use at your own risk. 

I created this script to do the following: First, it runs dnscan. It then takes the results of that, and filters it down to names and IP addresses. Once this is done, the results get run through Masscan to get an accurate list of ports. This is then fed into nmap. After nmap runs, gobuster runs in DNS mode with the identified ports, if there were any redirects it runs again, then takes the lists and combines them into one master hosts.txt file. That's the goal, anyway.

Again, you may need to tweak anything in here to fit your own needs. I am not responsible for your actions.

## DOWNLOAD INSTRUCTIONS:

Either copy and paste the raw code into your favorite text editor, or sudo git clone https://github.com/Fearless523/CloudEnum.git
