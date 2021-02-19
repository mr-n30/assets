#!/bin/bash

# Colors and format for output
RED="\e[4;31m"
END="\e[0m"
BOLD="\e[1m"
GREEN="\e[32m"
BLINK="\e[5m"
BANNER="\e[31m"
YELLOW="\e[1;33m"
UYELLOW="\e[4;33m"
MAGENTA="\e[95m"
INVERTED="\e[7m"

#############
# CHANGE ME #
#############
SECLISTS=/opt/SecLists
WORDLIST=/opt/p/wordlist.txt
TOOLS_DIR=/opt/tools
DNS_BRUTE=/opt/p/dns.txt
RESOLVERS=/opt/p/resolvers.txt
NMAP_TOP_PORTS=/opt/p/nmap-top-1000-ports.txt
SUBFINDER_CONFIG=/opt/p/config.yaml

# Print banner
echo -e "${BOLD}${BANNER}"
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
    echo -e "Subject: ${1} scan(s) complete for: ${3}" > /tmp/email.html
    echo -e "Content-Type: text/html\r\n" >> /tmp/email.html

	echo -e "<p>Directory: ${4}</p>" >> /tmp/email.html

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
	echo -e "${BOLD}${YELLOW}[*]${END} ${RED}You must specify a domain!${END}${END}"
	exit 1
fi

if ! $is_set_directory
then
    echo -e "${BOLD}${YELLOW}[*]${END} ${RED}You must specify a directory!${END}${END}"
    exit 1
else
    # Create directory to save all output
    if [ ! -d "$OUTPUT_DIR"  ]; then
        mkdir -p $OUTPUT_DIR
    fi
fi

if ! $is_set_email
then
    echo -e "${BOLD}${YELLOW}[*]${END} ${RED}You did not specify an email!${END}${END}"
    exit 1
fi

echo -e "${UYELLOW}${BOLD}DOMAIN   : ${DOMAIN}${END}${END}"
echo -e "${UYELLOW}${BOLD}EMAIL    : ${EMAIL}${END}${END}"
echo -e "${UYELLOW}${BOLD}WORDLIST : ${WORDLIST}${END}${END}"
echo -e "${UYELLOW}${BOLD}DIRECTORY: ${OUTPUT_DIR}${END}${END}"
sleep 3

# subfinder
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: subfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"

subfinder -v -d $DOMAIN -o $OUTPUT_DIR/subfinder.txt -all -config $SUBFINDER_CONFIG
sleep 3

# Start shuffledns
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: shuffledns${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"

shuffledns -v -d $DOMAIN -w $DNS_BRUTE -o $OUTPUT_DIR/shuffledns.txt -r $RESOLVERS -wt 100
sleep 3

# Sort all subdomains into one file
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: dnsx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"

cat $OUTPUT_DIR/*.txt | sort -u | dnsx -a -resp -verbose -o $OUTPUT_DIR/dnsx.out
awk -F' ' ' { print $2 } ' $OUTPUT_DIR/dnsx.out | sed -E 's/(\[|\])//g' | sort -u | tee -a $OUTPUT_DIR/ips.txt
awk -F' ' ' { print $1 } ' $OUTPUT_DIR/dnsx.out | sort -u | tee -a $OUTPUT_DIR/all.txt
sleep 3

# Start httpx
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: httpx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"

httpx \
    -no-fallback \
    -l $OUTPUT_DIR/all.txt \
    -o $OUTPUT_DIR/httpx.txt \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1" \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 (BUGCROWD; n30 / HACKERONE; mr_n30)'
sleep 3

# Begin screenshoting with gowitness
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: gowitness${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"

mkdir -p $OUTPUT_DIR/gowitness-httpx/screenshots
gowitness file \
    --threads 10 \
    --file $OUTPUT_DIR/httpx.txt \
    --db-path $OUTPUT_DIR/gowitness-httpx/gowitness.sqlite3 \
    --chrome-path /usr/bin/chromium-browser \
    --screenshot-path $OUTPUT_DIR/gowitness-httpx/screenshots \
    --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 (BUGCROWD; n30 / HACKERONE; mr_n30)'
sleep 3

# Send email
TYPE="Screenshot"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR
sleep 3

# Start corscanner
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: corscanner${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"

mkdir $OUTPUT_DIR/cors
cors \
	-i $OUTPUT_DIR/httpx.txt \
	-o $OUTPUT_DIR/cors/cors.json \
    --headers 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 (BUGCROWD; n30 / HACKERONE; mr_n30)'
sleep 3

# Start nuclei scan
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: nuclei${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"

mkdir $OUTPUT_DIR/nuclei
nuclei \
	-l $OUTPUT_DIR/httpx.txt \
	-o $OUTPUT_DIR/nuclei/nuclei.txt \
	-t $TOOLS_DIR/nuclei/nuclei-templates/dns/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/cves/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/takeovers/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/exposures/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/exposed-tokens/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/exposed-panels/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/vulnerabilities/ \
	-t $TOOLS_DIR/nuclei/nuclei-templates/misconfiguration/ \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 (BUGCROWD; n30 / HACKERONE; mr_n30)'
sleep 3

# Send email
TYPE="Basic"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR
sleep 3

# Start masscan
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: masscan${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"

masscan -v --rate=1000 -p$(cat $NMAP_TOP_PORTS) -oG $OUTPUT_DIR/masscan-output.gnmap -iL $OUTPUT_DIR/ips.txt
sleep 3

# Start nmap scan
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: nmap${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"

mkdir $OUTPUT_DIR/nmap
PORTS=$(grep -ioE '[0-9]{1,5}/[a-z]+' $OUTPUT_DIR/masscan-output.gnmap | sort -u | awk -F'/' '{ print $1 }' | tr '\n' ',' | sed 's/,$//g')
nmap -v -sC -sV -p$PORTS -oA $OUTPUT_DIR/nmap/nmap -iL $OUTPUT_DIR/all.txt
sleep 3

# Start screenshots nmap output
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: gowitness${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"

mkdir $OUTPUT_DIR/gowitness
gowitness nmap \
    --threads 10 \
    --file $OUTPUT_DIR/nmap/nmap.xml \
    --db-path $OUTPUT_DIR/gowitness/gowitness.sqlite3 \
    --chrome-path /usr/bin/chromium-browser \
    --screenshot-path $OUTPUT_DIR/gowitness/screenshots \
    --user-agent 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 (BUGCROWD; n30 / HACKERONE; mr_n30)'
sleep 3

# Brute-force for default credentials
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: brutespray${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"

mkdir $OUTPUT_DIR/brutespray
brutespray -c --file $OUTPUT_DIR/nmap/nmap.gnmap -o $OUTPUT_DIR/brutespray/ --threads 9 --hosts 3
sleep 3


# Start HTTP request smuggler
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: smuggler${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"

mkdir $OUTPUT_DIR/smuggler
smuggler -q -l $OUTPUT_DIR/smuggler/smuggler.txt < $OUTPUT_DIR/httpx.txt
sleep 3


echo -e "${MAGENTA}${BOLD}################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Running: dirsearch${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}################################################${END}${END}"

mkdir $OUTPUT_DIR/dirsearch
dirsearch -l $OUTPUT_DIR/httpx.txt -w $WORDLIST -i 200,400,405 -e .php,/,.txt --plain-text-report $OUTPUT_DIR/dirsearch/dirsearch.txt \
	--full-url \
	--force-extensions \
	-H 'X-Remote-IP: 127.0.0.1' \
	-H 'X-Remote-Addr: 127.0.0.1' \
	-H 'X-Originating-IP: 127.0.0.1' \
    --user-agent 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36 (BUGCROWD; n30 / HACKERONE; mr_n30)'
sleep 3

# Send email to user letting them know the script has finished
echo -e "${MAGENTA}${BOLD}################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Sending email to user${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}################################################${END}${END}"

TYPE="All"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR
sleep 3

# Done
echo -e "${YELLOW}${BOLD}[+] Done: $OUTPUT_DIR${END}${END}"
sleep 3
exit 0

