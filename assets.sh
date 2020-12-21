#!/bin/bash

# Colors and format for output
RED="\e[31m"
GREEN="\e[32m"
INVERTED="\e[7m"
BLINK="\e[5m"
BOLD="\e[1m"
END="\e[0m"

# argv[1] is the domain for the script
DOMAIN=$1
OUTPUT_DIR=$2/$1

if [[ "$#" -ne 2 ]]
then
	echo -e "Usage: ./assets.sh <domain> <directory_to_save_output>"
	exit 1
fi

# Check if root
if [[ $EUID -ne 0 ]]
then
	echo -e "$INVERTED$BLINK$RED$BOLD[!] You are not root...$END$END$END$END"
	echo -e "Usage: ./assets.sh <domain>"
	exit 1
fi

# Create directory to save all output
echo -e "$GREEN$BOLD[+] Creating directory to save ouput: $OUTPUT_DIR$END$END"
mkdir -p $OUTPUT_DIR/

# Begin subdomain enumeration
# amass
echo -e "$GREEN$BOLD[+] Running: amass$END$END"
amass enum -d $DOMAIN -o $OUTPUT_DIR/amass-output.txt -brute -active -config ./config.ini
sleep 300

# subfinder
echo -e "$GREEN$BOLD[+] Running: subfinder$END$END"
subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder-output.txt
sleep 300

# sublist3r
echo -e "$GREEN$BOLD[+] Running: sublist3r$END$END"
sublist3r -d $DOMAIN -o $OUTPUT_DIR/sublist3r-output.txt
sleep 300

# Sort all subdomains into one file
echo -e "$GREEN$BOLD[+] Sorting data...$END$END"
cat $OUTPUT_DIR/*.txt | sort -u | tee -a $OUTPUT_DIR/all-base.txt

# Begin subdomain brute-force with "massdns"
echo -e "$GREEN$BOLD[+] Running: massdns$END$END"
/opt/massdns/scripts/subbrute.py /usr/share/wordlists/dns.txt $DOMAIN | massdns -t A -o S -r /opt/massdns/lists/resolvers.txt -w $OUTPUT_DIR/massdns-output-brute.txt
# Clean massdns output file
sed 's/\s.*//g' $OUTPUT_DIR/massdns-output-brute.txt | sed 's/\.$//g' | sort -u > $OUTPUT_DIR/massdns-output-clean-brute.txt
cat $OUTPUT_DIR/massdns-output-clean-brute.txt $OUTPUT_DIR/all-base.txt | sort -u > $OUTPUT_DIR/all.txt

# Begin nuclei scan
# Check for cve's
httprobe < $OUTPUT_DIR/all.txt | nuclei -l $OUTPUT_DIR/all.txt -t /opt/nuclei/nuclei-templates/cves/ -o $OUTPUT_DIR/nuclei-cve.txt
# Check for subdomain takover
nuclei -l $OUTPUT_DIR/all.txt -t /opt/nuclei/nuclei-templates/subdomain-takeover/ -o $OUTPUT_DIR/nuclei-subdomains-takeover.txt
# Check for vulns
httprobe < $OUTPUT_DIR/all.txt | nuclei -l $OUTPUT_DIR/all.txt -t /opt/nuclei/nuclei-templates/vulnerabilities/ -o $OUTPUT_DIR/nuclei-vulns.txt

# Start nmap scan
echo -e "$GREEN$BOLD[+] Running: nmap$END$END"
mkdir $OUTPUT_DIR/nmap
## Top 1000 ports scan
nmap -T4 -v --open -oA $OUTPUT_DIR/nmap/top-1000-ports-syn-scan -iL $OUTPUT_DIR/all.txt
## Grep for data in files and store in variables
grep -oR 'Host:.*()' $OUTPUT_DIR/nmap/top-1000-ports-syn-scan.gnmap | awk '/\s/ { print $2 }' | sort -u | tee -a $OUTPUT_DIR/nmap/hosts.txt
PORTS=$(grep -oR 'Ports:.*$' $OUTPUT_DIR/nmap/top-1000-ports-syn-scan.gnmap | grep -oE '[0-9]{1,5}/' | sed 's/\///g' | sort -u | tr '\n' ',' | sed 's/,$//g')
## Default scan on open ports
nmap -T4 -v -p $PORTS -sC -sV --open -oA $OUTPUT_DIR/nmap/default-script-scan-on-ports -iL $OUTPUT_DIR/nmap/hosts.txt
## Vuln and default creds scan
nmap -T4 -v -p $PORTS --script vuln,http-default-accounts --open -oA $OUTPUT_DIR/nmap/vuln-default_creds-script-scan -iL $OUTPUT_DIR/nmap/hosts.txt

# geturls
#geturls -v -t 22 -o $OUTPUT_DIR/.geturls/ --nmap $OUTPUT_DIR/nmap/nmap-output.xml \
#-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0 - (BUGCROWD:n30 - HACKERONE:mr_n30)" \
#-H "X-Forwarded-For: 127.0.0.1" \
#-H "X-Originating-IP: 127.0.0.1" \
#-H "X-Remote-IP: 127.0.0.1" \
#-H "X-Remote-Addr: 127.0.0.1"

## Screenshot
echo -e "$GREEN$BOLD[+] Running: aquatone$END$END"
mkdir $OUTPUT_DIR/aquatone-nmap
aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-nmap -nmap < $OUTPUT_DIR/nmap/top-1000-ports-syn-scan.xml

## Done
#echo -e "$INVERTED$GREEN$BOLD[+] Data in: $OUTPUT_DIR/$END$END$END"
#echo -e "$INVERTED$BLINK$GREEN$BOLD[+] Done...$END$END$END$END"
