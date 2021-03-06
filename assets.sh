#!/bin/bash

# Colors and format for output
RED="\e[31m"
END="\e[0m"
BOLD="\e[1m"
URED="\e[4;31m"
GREEN="\e[32m"
BLINK="\e[5m"
YELLOW="\e[1;33m"
UYELLOW="\e[4;33m"
MAGENTA="\e[95m"
INVERTED="\e[7m"
BACKGROUND="\e[40m" # Black

# VARIABLES
SECLISTS=/opt/SecLists
WORDLIST=/opt/p/wordlist.txt
DNS_BRUTE=/opt/p/dns.txt
RESOLVERS=/opt/tools/fresh-resolvers/resolvers.txt
TOOLS_DIR=/opt/tools
AMASS_CONFIG=/opt/p/config.ini
NMAP_TOP_PORTS=/opt/p/nmap-top-1000-ports.txt
SUBFINDER_CONFIG=/opt/p/config.yaml
GITHUB_API_TOKEN=

# Print banner
echo -e "${BOLD}${RED}"
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
	echo -e "${URED}${BOLD}Usage: # $0 -d hackerone.com -o hackerone/ -e mr_n30@wearehackerone.com${END}${END}"
	exit 1
}

# send_email(type, email, domain, directory)
send_email() {

    echo -e "${MAGENTA}${BOLD}################################################${END}${END}"
    echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Sending email to user${END}${END}${END}"
    echo -e "${MAGENTA}${BOLD}################################################${END}${END}"
    sleep 3

	echo -e "${YELLOW}${BOLD}[+] Creating email template..."
	echo -e "Subject: ${1} scan finished for: ${3}" > /tmp/email.html
    echo -e "Content-Type: text/html\r\n" >> /tmp/email.html

	echo -e "<html><head><p>Directory: ${4}/</p></head><body>" >> /tmp/email.html

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
sleep 3

# subfinder
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: subfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"
sleep 3

subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder.txt -all -config $SUBFINDER_CONFIG
sleep 3

# massdns
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: massdns${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
sleep 3

$TOOLS_DIR/massdns/scripts/subbrute.py $DNS_BRUTE $DOMAIN | massdns -t A -o S -r $RESOLVERS -w $OUTPUT_DIR/massdns.out
sed 's/\s.*//g' $OUTPUT_DIR/massdns.out | sed 's/\.$//g' | sort -u | tee -a $OUTPUT_DIR/massdns-domains.txt
sleep 3

# Sort all subdomains into one file
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Sorting subdomains into one file${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
sleep 3

cat $OUTPUT_DIR/*.txt | sort -u | tee -a $OUTPUT_DIR/domains.txt
sleep 3

# dnsx
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: dnsx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
sleep 3

cat $OUTPUT_DIR/domains.txt | sort -u | dnsx -a -resp -verbose -o $OUTPUT_DIR/dnsx.out -r $RESOLVERS
awk -F' ' ' { print $2 } ' $OUTPUT_DIR/dnsx.out | sed -E 's/(\[|\])//g' | sort -u | tee -a $OUTPUT_DIR/ips.txt
awk -F' ' ' { print $1 } ' $OUTPUT_DIR/dnsx.out | sort -u | tee -a $OUTPUT_DIR/all.txt
rm $OUTPUT_DIR/domains.txt
sleep 3

# Start httpx
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: httpx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
sleep 3

httpx \
    -title \
    -no-color \
    -ports 80,443 \
    -o $OUTPUT_DIR/httpx.out \
	-l $OUTPUT_DIR/all.txt -no-fallback -silent \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1"

awk -F' ' '{ print $1 }' $OUTPUT_DIR/httpx.out | sort -u | tee -a $OUTPUT_DIR/httpx.txt

# Begin screenshots on httpx.txt
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: aquatone${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
sleep 3

aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-basic < $OUTPUT_DIR/httpx.txt

# Email
TYPE="Screenshot"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR

# Start corscanner
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: corscanner${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/cors
cors \
	-i $OUTPUT_DIR/httpx.txt \
	-o $OUTPUT_DIR/cors/cors.json \
	--headers 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)'

# Start nuclei scan
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: nuclei${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/nuclei
nuclei \
	-l $OUTPUT_DIR/httpx.txt \
	-o $OUTPUT_DIR/nuclei/nuclei.txt \
	-t $TOOLS_DIR/nuclei-templates/dns/ \
	-t $TOOLS_DIR/nuclei-templates/cves/ \
	-t $TOOLS_DIR/nuclei-templates/takeovers/ \
	-t $TOOLS_DIR/nuclei-templates/exposures/ \
	-t $TOOLS_DIR/nuclei-templates/exposed-tokens/ \
	-t $TOOLS_DIR/nuclei-templates/exposed-panels/ \
	-t $TOOLS_DIR/nuclei-templates/vulnerabilities/ \
	-t $TOOLS_DIR/nuclei-templates/misconfiguration/

# Find endpoints in wayback machine
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: waybackurls${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/wordlists
waybackurls < $OUTPUT_DIR/all.txt | tee -a $OUTPUT_DIR/wordlists/wb.txt
unfurl --unique keys < $OUTPUT_DIR/wordlists/wb.txt     | tee -a $OUTPUT_DIR/wordlists/keys.txt
unfurl --unique paths < $OUTPUT_DIR/wordlists/wb.txt    | tee -a $OUTPUT_DIR/wordlists/paths.txt
unfurl --unique keypairs < $OUTPUT_DIR/wordlists/wb.txt | tee -a $OUTPUT_DIR/wordlists/keypairs.txt

# gospider
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: gospider${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

gospider -S $OUTPUT_DIR/httpx.txt -t 10 -o $OUTPUT_DIR/gospider \
	-u 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1"
grep -R '^\[javascript\]' $OUTPUT_DIR/gospider/ | grep $DOMAIN | awk -F' ' '{ print $3 }' | sort -u | tee -a $OUTPUT_DIR/gospider-js.txt
sleep 300

# Find endpoints in JS files
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: subdomainizer${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/subdomainizer/
subdomainizer -l $OUTPUT_DIR/gospider-js.txt -g -gt $GITHUB_API_TOKEN -k -d $DOMAIN -sop $OUTPUT_DIR/subdomainizer/secrets.txt -cop $OUTPUT_DIR/subdomainizer/clouds.txt -o $OUTPUT_DIR/subdomainizer/subs.txt
sleep 300

# Find endpoints in JS files
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: linkfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

for URL in $(cat $OUTPUT_DIR/gospider-js.txt)
do
	linkfinder -i $URL -d -o cli | tee -a $OUTPUT_DIR/wordlists/linkfinder.tmp
done

sort -u $OUTPUT_DIR/wordlists/linkfinder.tmp | tee -a $OUTPUT_DIR/linkfinder.txt
rm $OUTPUT_DIR/wordlists/linkfinder.tmp
sleep 300

# smuggler
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: smuggler${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"

mkdir $OUTPUT_DIR/smuggler
sudo smuggler -q -l $OUTPUT_DIR/smuggler/smuggler.txt < $OUTPUT_DIR/httpx.txt
sleep 300

# ffuf
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: ffuf${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/brute
for URL in $(cat $OUTPUT_DIR/httpx.txt)
do
	domain_name=$(echo $URL | sed -E 's/(http:\/\/|https:\/\/)//g')
	echo -e "${MAGENTA}${BOLD}Trying: $domain_name$END$END"
	ffuf \
		-H "X-Remote-IP: 127.0.0.1" \
		-H "X-Remote-Addr: 127.0.0.1" \
		-H "X-Originating-IP: 127.0.0.1" \
		-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
		-s \
		-D \
		-fl 0,1,2,3,4 \
		-mc 200 \
		-timeout 0 \
		-maxtime 15 \
		-u $URL/FUZZ \
		-e .txt,.php,/ \
		-w $WORDLIST | tee -a $OUTPUT_DIR/brute/$domain_name.txt
done

# Email
TYPE="Basic"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR
sleep 3

# masscan
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: masscan${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
sleep 3

masscan -v --rate=100 -p$(cat $NMAP_TOP_PORTS) --open -oG $OUTPUT_DIR/masscan-output.gnmap -iL $OUTPUT_DIR/ips.txt
sleep 3

# nmap
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: nmap${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/nmap
PORTS=$(grep -ioE '[0-9]{1,5}/[a-z]+' $OUTPUT_DIR/masscan-output.gnmap | sort -u | awk -F'/' '{ print $1 }' | tr '\n' ',' | sed 's/,$//g')
nmap -v -n -Pn --script default,vuln -sV -p$PORTS -oA $OUTPUT_DIR/nmap/nmap -iL $OUTPUT_DIR/all.txt

# Begin screenshots
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: aquatone${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
sleep 3

aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone -nmap < $OUTPUT_DIR/nmap/nmap.xml
sleep 3

# Begin screenshots
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: brutespray${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/brutespray
brutespray --file $OUTPUT_DIR/nmap/nmap.gnmap --threads 5 --hosts 5 -c -o $OUTPUT_DIR/brutespray/
sleep 3

# Email
TYPE="Port"
send_email $TYPE $EMAIL $DOMAIN $OUTPUT_DIR
exit 0
