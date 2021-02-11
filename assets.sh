#!/bin/bash

# Colors and format for output
RED="\e[31m"
END="\e[0m"
BOLD="\e[1m"
GREEN="\e[32m"
BLINK="\e[5m"
YELLOW="\e[1;33m"
UYELLOW="\e[4;33m"
MAGENTA="\e[95m"
INVERTED="\e[7m"
BACKGROUND="\e[40m" # Black

#############
# CHANGE ME #
# VARIABLES #
#############
SECLISTS=/opt/SecLists
WORDLIST=/opt/p/wordlist.txt
TOOLS_DIR=/opt/tools
AMASS_CONFIG=/opt/p/config.ini
SUBFINDER_CONFIG=/opt/p/config.yaml

# Print banner
echo -e "${BOLD}${BACKGROUND}"
cat << EOF
 ▄▀▀█▄   ▄▀▀▀▀▄  ▄▀▀▀▀▄  ▄▀▀█▄▄▄▄  ▄▀▀▀█▀▀▄  ▄▀▀▀▀▄  ▄▀▀▀▀▄  ▄▀▀▄ ▄▄
▐ ▄▀ ▀▄ █ █   ▐ █ █   ▐ ▐  ▄▀   ▐ █    █  ▐ █ █   ▐ █ █   ▐ █  █   ▄▀
  █▄▄▄█    ▀▄      ▀▄     █▄▄▄▄▄  ▐   █        ▀▄      ▀▄   ▐  █▄▄▄█
 ▄▀   █ ▀▄   █  ▀▄   █    █    ▌     █      ▀▄   █  ▀▄   █     █   █
█   ▄▀   █▀▀▀    █▀▀▀    ▄▀▄▄▄▄    ▄▀        █▀▀▀ ▄  █▀▀▀     ▄▀  ▄▀
▐   ▐    ▐       ▐       █    ▐   █          ▐       ▐       █   █
                         ▐        ▐                          ▐   ▐
EOF
echo -e "${END}${END}"

# Check if root
if [[ $EUID -ne 0 ]]
then
	echo -e "$INVERTED$BLINK$RED$BOLD[!] You are not root!$END$END$END$END"
fi

usage() {
	echo "Usage: # $0 -d hackerone.com -o hackerone/ -e mr_n30@wearehackerone.com"
	exit 1
}

# send_email(type, email, domain, directory)
send_email() {
	echo -e "${YELLOW}${BOLD}[+] Creating email for: ${2}${END}${END}"
	echo -e "Subject: ${1} scan finished for: ${3}" > /tmp/email.html
    echo -e "Content-Type: text/html\r\n" >> /tmp/email.html

	echo -e "<html><head></head><body>" >> /tmp/email.html
	echo -e "<h3>Directory: ${4}/</h3>" >> /tmp/email.html
	echo -e "<pre><strong><p>" >> /tmp/email.html

	echo -en "Lines in amass.txt: " >> /tmp/email.txt
    wc --lines ${4}/amass.txt >> /tmp/email.txt

	echo -en "Lines in subfinder.txt: " >> /tmp/email.txt
    wc --lines ${4}/subfinder.txt >> /tmp/email.txt

	echo -en "Lines in sublist3r.txt: " >> /tmp/email.txt
    wc --lines ${4}/sublist3r.txt >> /tmp/email.txt

	echo -e "</p></strong></pre>" >> /tmp/email.html
	echo -e "</body></html>" >> /tmp/email.html

	echo -e "${YELLOW}${BOLD}[+] Sending email to: ${2}${END}${END}"
	ssmtp $2 < /tmp/email.html

	echo -e "${YELLOW}${BOLD}[+] Email sent...${END}${END}"
	rm /tmp/email.html
}

# Parse command line arguments
is_set_email=false
is_set_domain=false
is_set_directory=false
while getopts ":d:o:e:h" OPTION; do
	case "${OPTION}" in
		d)
			DOMAIN="${OPTARG}"
			is_set_domain=true
			;;
		o)
			OUTPUT_DIR="${OPTARG}"
            is_set_directory=true
			;;
		e)
			EMAIL="${OPTARG}"
			is_set_email=true
			;;
		\?)
			usage
			;;
		*)
			usage
			;;
	esac
done
shift $((OPTIND - 1))

# Check if required arguments are set
if ! $is_set_domain
then
	echo -e "${RED}${BOLD}[*] You must specify a domain!${END}${END}"
	exit 1
fi

if ! $is_set_directory
then
    echo -e "${RED}${BOLD}[*] You must specify a directory!${END}${END}"
    exit 1
else
    # Create directory to save all output
    if [ ! -d "$OUTPUT_DIR"  ]; then
        mkdir -p $OUTPUT_DIR
    fi
fi

if ! $is_set_email
then
    echo -e "${RED}${BOLD}[*] No email specified${END}${END}"
    exit 1
fi

echo -e "${UYELLOW}${BOLD}DOMAIN   : ${DOMAIN}${END}${END}"
echo -e "${UYELLOW}${BOLD}WORDLIST : ${WORDLIST}${END}${END}"
echo -e "${UYELLOW}${BOLD}DIRECTORY: ${OUTPUT_DIR}${END}${END}"
echo -e "${UYELLOW}${BOLD}EMAIL    : ${EMAIL}${END}${END}"

# Begin subdomain enumeration

# subfinder
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: subfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"

subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder.txt -all -config $SUBFINDER_CONFIG
sleep 300

# amass
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: amass${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"

amass enum -d $DOMAIN -o $OUTPUT_DIR/amass.txt
sleep 300

# sublist3r
echo -e "${MAGENTA}${BOLD}#############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: sublist3r${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#############################################${END}${END}"

sublist3r -d $DOMAIN -o $OUTPUT_DIR/sublist3r.txt
sleep 3

# Start subdomain brute-force with massdns
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: massdns${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"

$TOOLS_DIR/massdns/scripts/subbrute.py $SECLISTS/Discovery/DNS/dns-Jhaddix.txt $DOMAIN | massdns -t A -o S -r $TOOLS_DIR/massdns/lists/resolvers.txt -w $OUTPUT_DIR/massdns.out
sleep 3

# Sort all subdomains into one file
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Sorting subdomains into one file${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"

sed 's/\s.*//g' $OUTPUT_DIR/massdns.out | sed 's/\.$//g' | sort -u | tee -a $OUTPUT_DIR/massdns-domains.txt
cat $OUTPUT_DIR/*.txt | sort -u | tee -a $OUTPUT_DIR/all.txt
sleep 3

# Start httpx
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: httpx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"

httpx \
	-l $OUTPUT_DIR/all.txt -no-fallback -silent \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1" | tee -a $OUTPUT_DIR/httpx.txt

# Begin screenshots on httpx.txt
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: aquatone${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"

mkdir $OUTPUT_DIR/aquatone-basic
aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-basic -ports xlarge < $OUTPUT_DIR/httpx.txt

# Send email to user notifying them that a 'Basic' scan has completed
TYPE="Basic"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR

# Start corscanner
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: corscanner${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"

mkdir $OUTPUT_DIR/cors
cors \
	-i $OUTPUT_DIR/httpx.txt \
	-o $OUTPUT_DIR/cors/cors.json \
	--headers 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)'

# Start nuclei scan
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: nuclei${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"

mkdir $OUTPUT_DIR/nuclei
nuclei -l $OUTPUT_DIR/httpx.txt -o $OUTPUT_DIR/nuclei/nuclei.txt -t $TOOLS_DIR/nuclei/nuclei-templates/
#nuclei \
#	-l $OUTPUT_DIR/httpx.txt \
#	-o $OUTPUT_DIR/nuclei/nuclei.txt \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/dns/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/cves/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/takeovers/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/exposures/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/exposed-tokens/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/exposed-panels/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/vulnerabilities/ \
#	-t $TOOLS_DIR/nuclei/nuclei-templates/misconfiguration/

# Start masscan
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: masscan${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"

for DNS in $(cat $OUTPUT_DIR/all.txt); do
    dig +short $DNS | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | tee -a $OUTPUT_DIR/ip.txt
done
sort -u $OUTPUT_DIR/ip.txt | tee -a $OUTPUT_DIR/ips.txt && rm $OUTPUT_DIR/ip.txt

masscan -v --rate=10000 -p0-65535 --open -oG $OUTPUT_DIR/masscan-output.gnmap -iL $OUTPUT_DIR/ips.txt
sleep 3

# Start nmap scan
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: nmap${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"

mkdir $OUTPUT_DIR/nmap
PORTS=$(grep -ioE '[0-9]{1,5}/[a-z]+' $OUTPUT_DIR/masscan-output.gnmap | sort -u | awk -F'/' '{ print $1 }' | tr '\n' ',' | sed 's/,$//g')
nmap -v -sV -n -p$PORTS -oA $OUTPUT_DIR/nmap/nmap -iL $OUTPUT_DIR/all.txt

# Begin screenshots
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: aquatone${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"

mkdir $OUTPUT_DIR/aquatone
aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone -nmap < $OUTPUT_DIR/nmap/nmap.xml
sleep 3

# Find endpoints in wayback machine
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: waybackurls${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"

mkdir $OUTPUT_DIR/wordlists
waybackurls < $OUTPUT_DIR/all.txt | tee -a $OUTPUT_DIR/wordlists/wb.txt
unfurl --unique keys < $OUTPUT_DIR/wordlists/wb.txt     | tee -a $OUTPUT_DIR/wordlists/keys.txt
unfurl --unique paths < $OUTPUT_DIR/wordlists/wb.txt    | tee -a $OUTPUT_DIR/wordlists/paths.txt
unfurl --unique keypairs < $OUTPUT_DIR/wordlists/wb.txt | tee -a $OUTPUT_DIR/wordlists/keypairs.txt
sleep 3

# Start brute-forcing directories
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: ffuf${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"

mkdir $OUTPUT_DIR/brute
for URL in $(cat $OUTPUT_DIR/httpx.txt); do
	domain_name=$(echo $URL | sed -E 's/(http:\/\/|https:\/\/)//g')
	echo -e "${MAGENTA}${BOLD}Trying: $domain_name$END$END"
	ffuf \
		-H "X-Remote-IP: 127.0.0.1" \
		-H "X-Remote-Addr: 127.0.0.1" \
		-H "X-Originating-IP: 127.0.0.1" \
		-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
		-s \
		-D \
		-mc 200 \
		-timeout 0 \
		-maxtime 15 \
		-u $URL/FUZZ \
		-e .txt,.php \
		-w $WORDLIST | tee -a $OUTPUT_DIR/brute/$domain_name.txt
done

# Find endpoints in JS files
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: linkfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"

for URL in $(cat $OUTPUT_DIR/httpx.txt); do
	linkfinder -i $URL -d -o cli | sort -u | tee -a $OUTPUT_DIR/wordlists/linkfinder.tmp
done;

sort -u $OUTPUT_DIR/wordlists/linkfinder.tmp | tee -a $OUTPUT_DIR/linkfinder.txt
rm $OUTPUT_DIR/wordlists/linkfinder.tmp

# Send email to user letting them know
# the script has finished
echo -e "${MAGENTA}${BOLD}################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Sending email to user${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}################################################${END}${END}"

TYPE="Final"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR

# Done
echo -e "${YELLOW}${BOLD}[+] Done: $OUTPUT_DIR${END}${END}"
exit 0
