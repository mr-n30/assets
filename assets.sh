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

#subfinder
echo -e "$GREEN$BOLD[+] Running: subfinder$END$END";
subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder-output.txt

# amass
echo -e "$GREEN$BOLD[+] Running: amass$END$END";
amass enum -d $DOMAIN -o $OUTPUT_DIR/amass-output.txt -brute -active;

# sublist3r
echo -e "$GREEN$BOLD[+] Running: sublist3r$END$END";
sublist3r -d $DOMAIN -o $OUTPUT_DIR/sublist3r-output.txt;

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

# Go into "target" directory
cd $OUTPUT_DIR/;

# Sort all subdomains into one file
echo -e "$GREEN$BOLD[+] Cleaning output and sorting into one file: all.txt$END$END";
cat *.txt \
| sort -u \
| tee -a all.txt;

# Create wordlist for altdns
mkdir altdns/;
echo $DOMAIN > altdns/subdomains.txt;
sed "s/$DOMAIN//g" all.txt \
| sed 's/\./\n/g' \
| sed '/^$/d' \
| sort -u > altdns/words.txt;

# geturls
geturls -t 50 -o geturls/ -f all.txt \
-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0" \
-H "X-Forwarded-For: 127.0.0.1" \
-H "X-Originating-IP: 127.0.0.1" \
-H "X-Remote-IP: 127.0.0.1" \
-H "X-Remote-Addr: 127.0.0.1";

# Nmap scan
#echo -e "$GREEN$BOLD[+] Checking for live host(s)$END$END";
#cd $OUTPUT_DIR/;
#mkdir nmap;
#echo -e "$GREEN$BOLD[+] Running: nmap$END$END";
#nmap -Pn -n -T4 -sS --min-rate=1000 -v -oA $OUTPUT_DIR/nmap/nmap-output -iL $OUTPUT_DIR/all.txt

# Screenshot
#echo -e "$GREEN$BOLD[+] Running: aquatone$END$END";
#mkdir $OUTPUT_DIR/aquatone-nmap
#aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-nmap -nmap < $OUTPUT_DIR/nmap/nmap-output.xml

## Done
echo -e "$INVERTED$GREEN$BOLD[+] Contents in: $OUTPUT_DIR/$END$END$END";
echo -e "$INVERTED$BLINK$GREEN$BOLD[+] D O N E . . .$END$END$END$END";
