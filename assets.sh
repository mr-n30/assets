#!/bin/bash

# Colors and format for output
RED="\e[31m"
GREEN="\e[32m"
INVERTED="\e[7m"
BLINK="\e[5m"
BOLD="\e[1m"
END="\e[0m"

# argv[1] is the domain for the script
DOMAIN=$2
OUTPUT_DIR=$1/$2

if [[ "$#" -ne 2 ]]
then
	echo -e "Usage: $0 <directory> <domain>"
	exit 1
fi

# Check if root
if [[ $EUID -ne 0 ]]
then
	echo -e "$INVERTED$BLINK$RED$BOLD[!] You are not root...$END$END$END$END"
	echo -e "Usage: $0 <directory> <domain>"
	exit 1
fi

# Create directory to save all output
if [ ! -d "$OUTPUT_DIR"  ]; then
    mkdir -p $OUTPUT_DIR
fi

# Begin subdomain enumeration
# amass
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: amass     ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

amass enum -d $DOMAIN -o $OUTPUT_DIR/amass-output.txt -brute -active -config ./config.ini
sleep 300

# subfinder
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: subfinder ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder-output.txt -all
sleep 300

# sublist3r
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: sublist3r ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

sublist3r -d $DOMAIN -o $OUTPUT_DIR/sublist3r-output.txt
sleep 300

# Sort all subdomains into one file
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Sorting data...    ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"
cat $OUTPUT_DIR/*.txt | sort -u | tee -a $OUTPUT_DIR/all-base.txt

# Begin subdomain brute-force with "massdns"
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: massdns   ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

/opt/massdns/scripts/subbrute.py /usr/share/wordlists/dns.txt $DOMAIN | massdns -t A -o S -r /opt/massdns/lists/resolvers.txt -w $OUTPUT_DIR/massdns-output-brute.txt

# Clean massdns output file
sed 's/\s.*//g' $OUTPUT_DIR/massdns-output-brute.txt | sed 's/\.$//g' | sort -u > $OUTPUT_DIR/massdns-output-clean-brute.txt
cat $OUTPUT_DIR/massdns-output-clean-brute.txt $OUTPUT_DIR/all-base.txt | sort -u > $OUTPUT_DIR/all.txt

# Begin nuclei scan
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: nuclei    ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

mkdir -p $OUTPUT_DIR/nuclei
httpx \
	-H "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)" \
	-no-fallback \ 
	-silent < $OUTPUT_DIR/all.txt | tee -a $OUTPUT_DIR/httpx.txt
nuclei \ 
	-l $OUTPUT_DIR/httpx.txt  \
	-t /opt/nuclei/nuclei-templates/cves/ \ 
	-t /opt/nuclei/nuclei-templates/dns/  \
	-t /opt/nuclei/nuclei-templates/vulnerabilities/ \ 
	-t /opt/nuclei/nuclei-templates/takeovers/ \ 
	-t /opt/nuclei/nuclei-templates/misconfiguration/ \ 
	-t /opt/nuclei/nuclei-templates/exposures/ \ 
	-t /opt/nuclei/nuclei-templates/exposed-panels/ \ 
	-o $OUTPUT_DIR/nuclei/nuclei.txt

# Start masscan
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: masscan   ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

for DNS in $(cat $OUTPUT_DIR/all.txt); do
    dig +short $DNS | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | sort -u | tee -a $OUTPUT_DIR/ips.txt
done

masscan -v --rate=10000 -p0-65535 --open -oG $OUTPUT_DIR/masscan-output.gnmap -iL $OUTPUT_DIR/ips.txt

# Start nmap scan
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: nmap      ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

mkdir $OUTPUT_DIR/nmap

PORTS=$(grep -ioE '[0-9]{1,5}/[a-z]+' $OUTPUT_DIR/masscan-output.gnmap | awk -F'/' '{ print $1 }' | tr '\n' ',' | sed 's/,$//g')

## Default script scan on open ports
nmap -v -T4 -sC -sV -n -p$PORTS --open -oA $OUTPUT_DIR/nmap/default-script-scan -iL $OUTPUT_DIR/all.txt

## Screenshot
echo -e "$GREEN$BOLD##############################$END$END"
echo -e "$GREEN$BOLD### [+] Running: aquatone  ###$END$END"
echo -e "$GREEN$BOLD##############################$END$END"

mkdir $OUTPUT_DIR/aquatone
aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone -nmap < $OUTPUT_DIR/nmap/default-script-scan.xml

echo -e "$GREEN$BOLD[+] All output in: $OUTPUT_DIR$END$END"
