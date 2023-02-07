
#!/usr/bin/env python3
# You may need to perform pip install python-nmap for this to work

import os
import argparse
import nmap

def parse_arguments():
    parser = argparse.ArgumentParser(description='DNS Recon enumeration script')
    parser.add_argument('domain', type=str, help='Target domain for dnsrecon')
    parser.add_argument('name_server', type=str, help='Target Nameserver for dnsrecon')
    return parser.parse_args()

def run_dnsrecon(domain, name_server, file_number):
    os.system(f'dnsrecon --iw -d {domain} -D /usr/share/wordlist/seclists/Discovery/DNS/subdomains-top1million-20000.txt -k -t brt,crt,std -n {name_server} --threads 10 -o {file_number}.csv')

def sort_and_filter_results(file_number):
    os.system(f'cat {file_number}.csv | awk -F, \'{{ print tolower($2) }}\' | sort -u | grep -v name | grep -v dns > filtered{file_number}.csv')
    os.system(f'cat filtered{file_number}.csv | grep -v dns | grep -v MX | grep -v : | grep -v heroku | awk -F, \'{{ print $3 }}\' | grep -v "^$" | grep -v Address > temp-ips.txt')

def merge_and_sort_ips():
    os.system(f'cat temp-ips.txt | sort -u > ips.txt')
    os.remove('temp-ips.txt')

def run_masscan(filename):
    os.system(f'masscan -iL {filename} -oG masscan.txt')
    os.system(f'cat masscan.txt | grep Host | awk \'{{ print $5 }}\' | awk -F/ \'{{ print $1 }}\' | grep [0-9] | sort -u | tr \'\\n\' \',\' > portlist.txt')

def main():
    args = parse_arguments()
    run_dnsrecon(args.domain, 1)
    sort_and_filter_results(1)
    redirect_location = None

    with open('filtered1.csv', 'r') as file:
        for line in file:
            if 'redirect' in line.lower():
                redirect_location = line.split(',')[2].strip()
                break

    if redirect_location:
        run_dnsrecon(redirect_location, 2)
        sort_and_filter_results(2)
        merge_and_sort_ips()
    else:
        merge_and_sort_ips()

    run_masscan('ips.txt')

def run_nmap(ip_file, port_file):
    with open(ip_file, 'r') as ip_list:
        ips = ip_list.read().strip()
    with open(port_file, 'r') as port_list:
        ports = port_list.read().strip()
    nm = nmap.PortScanner()
    command = f'nmap -iL {ips} -p "{ports}" -n -O -sV --script redis-info,mongodb-databases,http-git,http-methods,http-passwd --reason -Pn -oA scan1'
    nm.scan(hosts=ips, arguments=command)

def main():
    ...
    run_masscan('ips.txt')
    run_nmap('ips.txt', 'portlist.txt')
    ...

if __name__ == '__main__':
    main()
