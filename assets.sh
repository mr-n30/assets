#!/bin/bash

# Colors and format for output
RED="\e[31m";
GREEN="\e[32m";
INVERTED="\e[7m";
BLINK="\e[5m";
BOLD="\e[1m";
END="\e[0m";

# argv[1] is the domain for the script
DOMAIN=$1

OUTPUT_DIR=~/targets/$DOMAIN

###############
# BEGIN SETUP #
###############
# argc
if [[ "$#" -ne 1 ]];
then
	echo -e "Usage: ./assets.sh <domain>";
	exit 1;
fi

# Check if root
if [[ $EUID -ne 0 ]];
then
	echo -e "$INVERTED$BLINK$RED$BOLD[!] You are not root...$END$END$END$END";
	echo -e "Usage: ./assets.sh <domain>";
	exit 1;
fi

# Create directory to save all output
echo -e "$GREEN$BOLD[+] Creating directory to save ouput: $OUTPUT_DIR$END$END";
mkdir -p $OUTPUT_DIR/;
#############
# END SETUP #
#############


###############################
# BEGIN SUBDOMAIN ENUMERATION #
###############################
# amass
echo -e "$GREEN$BOLD[+] Running: amass$END$END";
amass enum -d $DOMAIN -o $OUTPUT_DIR/amass-output.txt -brute -active -config ./config.ini
sleep 300

#subfinder
echo -e "$GREEN$BOLD[+] Running: subfinder$END$END";
subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder-output.txt
sleep 300

# sublist3r
echo -e "$GREEN$BOLD[+] Running: sublist3r$END$END";
sublist3r -d $DOMAIN -o $OUTPUT_DIR/sublist3r-output.txt;
sleep 300

# bufferover.run
curl -s "https://dns.bufferover.run/dns?q=.$DOMAIN" \
| jq -r ".FDNS_A[]" \
| cut -d',' -f2 \
| sort -u \
| tee -a $OUTPUT_DIR/bufferover.run-output.txt;

# crt.sh
curl "https://crt.sh/?q=%.$DOMAIN&output=json" \
| jq ".[].name_value" \
| sed "s/\"//g" \
| sed "s/\*\.//g" \
| sed "s/\\n/\n/g" \
| grep -oE ".*\.$DOMAIN\.com$" \
| sort -u \
| tee -a $OUTPUT_DIR/crt.sh-output.txt;
#############################
# END SUBDOMAIN ENUMERATION #
#############################

# Go into "target" directory
cd $OUTPUT_DIR/;

# Sort all subdomains into one file
echo -e "$GREEN$BOLD[+] Cleaning output and sorting into one file: all-base.txt$END$END";
cat *.txt \
| sort -u \
| tee -a all-base.txt;

###############################
# BEGIN SUBDOMAIN BRUTE-FORCE #
###############################
# massdns
echo -e "$GREEN$BOLD[+] Running: massdns$END$END";
/opt/massdns/scripts/subbrute.py /usr/share/wordlists/dns.txt $DOMAIN \
| massdns -t A -o S -r /opt/massdns/lists/resolvers.txt -w $OUTPUT_DIR/massdns-output-brute.txt;
# Clean massdns output file
sed 's/\s.*//g' $OUTPUT_DIR/massdns-output-brute.txt \
| sed 's/\.$//g' \
| sort -u > $OUTPUT_DIR/massdns-output-clean-brute.txt;
cat $OUTPUT_DIR/massdns-output-clean-brute.txt $OUTPUT_DIR/all-base.txt \
| sort -u > $OUTPUT_DIR/all.txt;
#############################
# END SUBDOMAIN BRUTE-FORCE #
#############################

# Go into "target" directory
cd $OUTPUT_DIR/;

################
# BEGIN NUCLEI #
################
# Check for cve's
httprobe < $OUTPUT_DIR/all.txt | nuclei -l $OUTPUT_DIR/all.txt -t /opt/nuclei/nuclei-templates/cves/ -o $OUTPUT_DIR/nuclei-cve.txt
# Check for subdomain takover
nuclei -l $OUTPUT_DIR/all.txt -t /opt/nuclei/nuclei-templates/subdomain-takeover/ -o $OUTPUT_DIR/nuclei-subdomains-takeover.txt
# Check for vulns
httprobe < $OUTPUT_DIR/all.txt | nuclei -l $OUTPUT_DIR/all.txt -t /opt/nuclei/nuclei-templates/vulnerabilities/ -o $OUTPUT_DIR/nuclei-vulns.txt
##############
# END NUCLEI #
##############

# Nmap
echo -e "$GREEN$BOLD[+] Running: nmap$END$END";
mkdir nmap;
## All ports scan
nmap -Pn -v -p- -sS --open -oA $OUTPUT_DIR/nmap/all-ports-scan -iL $OUTPUT_DIR/all.txt;
## Grep for data in files and store in variables
HOSTS=$(grep -oR 'Host:.*()' $OUTPUT_DIR/nmap/all-ports-scan.gnmap | awk '/\s/ { print $2 }' | sort -u | tee -a $OUTPUT_DIR/nmap/hosts.txt)
PORTS=$(grep -oR 'Ports:.*$' $OUTPUT_DIR/nmap/all-ports-scan.gnmap | grep -oE '[0-9]{1,5}/' | sed 's/\///g' | sort -u | tr '\n' ',' | sed 's/,$//g')
## Default scan on open ports
nmap -Pn -v -p $PORTS -sC -sV --open -oA $OUTPUT_DIR/nmap/default-script-scan -iL $OUTPUT_DIR/nmap/hosts.txt;
## Vuln and default creds scan
nmap -Pn -v -p $PORTS --script vuln,http-default-accounts --open -oA $OUTPUT_DIR/nmap/vuln-default_creds-script-scan -iL $OUTPUT_DIR/nmap/hosts.txt;

# geturls
geturls -v -t 22 -o $OUTPUT_DIR/.geturls/ --nmap $OUTPUT_DIR/nmap/nmap-output.xml \
-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0 - (BUGCROWD - HACKERONE)" \
-H "X-Forwarded-For: 127.0.0.1" \
-H "X-Originating-IP: 127.0.0.1" \
-H "X-Remote-IP: 127.0.0.1" \
-H "X-Remote-Addr: 127.0.0.1";

## Screenshot
echo -e "$GREEN$BOLD[+] Running: aquatone$END$END";
mkdir $OUTPUT_DIR/aquatone-nmap
aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-nmap -nmap < $OUTPUT_DIR/nmap/nmap-output.xml

## Done
echo -e "$INVERTED$GREEN$BOLD[+] Data in: $OUTPUT_DIR/$END$END$END";
echo -e "$INVERTED$BLINK$GREEN$BOLD[+] Done...$END$END$END$END";
