#!/bin/bash

# Take the domain and nameserver as input
echo "Enter the domain: "
read domain
echo "Enter the nameserver: "
read name_server

# First run of dnsrecon
dnsrecon --iw -d $domain -D /usr/share/wordlist/seclists/Discovery/DNS/subdomains-top1million-20000.txt -k -t brt,crt,std -n $name_server --threads 10 -c dnsrecon.csv

# Check if there are any redirects
if grep -q "CNAME" dnsrecon.csv; then
  # Get the redirected domain
  redirect=$(grep "CNAME" dnsrecon.csv | awk -F, '{ print $3 }' | awk -F. '{ print $2"."$3 }')
  # Run dnsrecon again against the redirected domain
  dnsrecon --iw -d $redirect -D /usr/share/wordlist/seclists/Discovery/DNS/subdomains-top1million-20000.txt -k -t brt,crt,std -n $name_server --threads 10 -c dnsrecon2.csv
  # Combine the results from both dnsrecon runs
  cat dnsrecon.csv dnsrecon2.csv | grep -v dns | grep -v MX | grep -v : | grep -v heroku | awk -F, '{ print $3 }' | grep -v "^$" | grep -v Address > temp-ips.txt
else
  # Use the results from the first dnsrecon run
  cat dnsrecon.csv | grep -v dns | grep -v MX | grep -v : | grep -v heroku | awk -F, '{ print $3 }' | grep -v "^$" | grep -v Address > temp-ips.txt
fi

# Sort the IPs and remove duplicates
cat temp-ips.txt | sort -u > ips.txt

# Run masscan to identify open ports
sudo masscan -iL ips.txt -p 0-65535 --adapter tap0 -oG masscan.txt

# Extract the unique list of open ports
cat masscan.txt | grep Host | awk '{ print $5 }' | awk -F/ '{ print $1 }' | grep [0-9] | sort -u | tr '\n' ',' > portlist.txt

# Run nmap with the identified ports
sudo nmap -iL ips.txt -p 'echo $(cat portlist.txt)' -n -O -sV --script redis-info,mongodb-databases,http-git,http-methods,http-passwd

#Run Gobuster with the identified ports
sudo gobuster dns -d $domain -t -q -w /usr/share/wordlist/seclists/Discovery/DNS/subdomains-top1million-20000.txt -o gobuster-hosts -r $name_server

#Check if there are any redirects
if grep -q "CNAME" dnsrecon.csv; then

#Get the redirected domain
redirect=$(grep "CNAME" dnsrecon.csv | awk -F,'{ print $3 }' | awk -F.'{ print $2"."$3 }')

#Run gobuster dns on the redirected domain
gobuster dns -d $redirect -t -q -w /usr/share/wordlist/seclists/Discovery/DNS/subdomains-top1million-20000.txt -o gobuster-hosts2 -r $name_server

#Combine the results from the dnsrecon and gobuster into a single file
cat dnsrecon.csv | grep -v dns | grep -v MX | grep -v route | awk -F, '{ print tolower($2) }' | grep -v name | sort -u | grep -v s3-1-w | grep -v s3-website-us-east-1 > host_temp.txt
cat dnsrecon2.csv | grep -v dns | grep -v office | grep -v MX | awk -F, '{ print tolower($2) }' | grep -v name | sort -u >> host_temp.txt
cat gobuster-hosts | awk -F, '{ print tolower($2) }' | awk '{ print $1 }' | sort -u >> host_temp.txt
cat gobuster-hosts2 | awk -F, '{ print tolower($2) }' | awk '{ print $1 }' | sort -u >> host_temp.txt
cat host_temp.txt | sort -u > hosts.txt
