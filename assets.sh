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
echo -e "$GREEN$BOLD[+] Cleaning output and sorting into one file: all-base.txt$END$END";
cat *.txt \
| sort -u \
| tee -a all-base.txt;

# altdns
echo -e "$GREEN$BOLD[+] Running: altdns$END$END";
mkdir altdns/;
cd altdns/;
echo $DOMAIN > subdomains.txt;

# Create altnds wordlist
sed "s/$DOMAIN//g" ../all-base.txt \
| sed 's/\./\n/g' \
| sed '/^$/d' \
| sort -u > words.txt;

# run altdns
altdns -i subdomains.txt -o output.txt -w words.txt -t 50;
mv output.txt subdomains.txt;
altdns -i subdomains.txt -o output.txt -w words.txt -t 50;
cat subdomains.txt output.txt > all.txt;

# massdns
echo -e "$GREEN$BOLD[+] Running: massdns$END$END";
massdns -o S -r /opt/massdns/lists/resolvers.txt -w $OUTPUT_DIR/massdns-output.txt all.txt;

# Clean massdns output file
sed 's/\s.*//g' $OUTPUT_DIR/massdns-output.txt \
| sed 's/\.$//g' > $OUTPUT_DIR/massdns-output-clean.txt;

# Go into "target" directory
cd $OUTPUT_DIR/;

# Sort subdomains one last time
echo -e "$GREEN$BOLD[+] Cleaning output and sorting into one file: all.txt$END$END";
cat all-base.txt massdns-output-clean.txt \
| sort -u \
| tee -a all.txt;

# geturls
geturls -t 22 -o geturls/ -f all.txt \
-H "User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:80.0) Gecko/20100101 Firefox/80.0 - (BUGCROWD - HACKERONE)" \
-H "X-Forwarded-For: 127.0.0.1" \
-H "X-Originating-IP: 127.0.0.1" \
-H "X-Remote-IP: 127.0.0.1" \
-H "X-Remote-Addr: 127.0.0.1";

# Nmap
echo -e "$GREEN$BOLD[+] Running: nmap$END$END";
cd $OUTPUT_DIR/;
mkdir nmap;
nmap -Pn -n -T4 -sS -v --min-rate=1000 -oX $OUTPUT_DIR/nmap/nmap-output.xml -iL $OUTPUT_DIR/all.txt;

# Screenshot
#echo -e "$GREEN$BOLD[+] Running: aquatone$END$END";
#mkdir $OUTPUT_DIR/aquatone-nmap
#aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-nmap -nmap < $OUTPUT_DIR/nmap/nmap-output.xml

## Done
echo -e "$INVERTED$GREEN$BOLD[+] Data in: $OUTPUT_DIR/$END$END$END";
echo -e "$INVERTED$BLINK$GREEN$BOLD[+] Done...$END$END$END$END";
