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
NMAP_TOP_PORTS=/opt/p/nmap-top-1000-ports.txt
SUBFINDER_CONFIG=/opt/p/config.yaml
GIT=

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

    echo -e "To: ${EMAIL}" >> /tmp/email-template.txt && \
    echo -e "From: $USER@$(cat /etc/hostname)" >> /tmp/email-template.txt && \
    echo -e "Content-Type: text/plain;" >> /tmp/email-template.txt
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
echo -e "${UYELLOW}${BOLD}RCPT     : ${EMAIL}${END}${END}"
echo -e "${UYELLOW}${BOLD}WORDLIST : ${WORDLIST}${END}${END}"
echo -e "${UYELLOW}${BOLD}DIRECTORY: ${OUTPUT_DIR}${END}${END}"
sleep 3

# subfinder
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: subfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}######################################${END}${END}"
sleep 3

subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder.txt -all -config $SUBFINDER_CONFIG
sleep 3

# naabu
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: naabu+httpx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/naabu
naabu -top-ports 100 -iL $OUTPUT_DIR/subfinder.txt -c 100 -verify -stats -scan-all-ips -timeout 100 -o $OUTPUT_DIR/naabu/naabu-100.txt
sleep 3

mkdir $OUTPUT_DIR/httpx
httpx \
    -title \
	-silent \
    -no-color \
	-no-fallback \
    -o $OUTPUT_DIR/httpx/httpx-100.out \
	-l $OUTPUT_DIR/naabu/naabu-100.txt \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1"

awk -F' ' '{ print $1 }' $OUTPUT_DIR/httpx/httpx-100.out | sort -u | tee -a $OUTPUT_DIR/httpx/httpx-100.txt

# gospider
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: gospider${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

gospider -S $OUTPUT_DIR/httpx/httpx-100.txt -t 10 -o $OUTPUT_DIR/gospider \
	-u 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1"
grep -R '^\[javascript\]' $OUTPUT_DIR/gospider/ | grep $DOMAIN | awk -F' ' '{ print $3 }' | sort -u | tee -a $OUTPUT_DIR/gospider/gospider-js.txt
sleep 300

# create
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Creating custom wordlists${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/wordlists

waybackurls < $OUTPUT_DIR/subfinder.txt | tee -a $OUTPUT_DIR/wordlists/wb.txt
unfurl --unique keys < $OUTPUT_DIR/wordlists/wb.txt     | tee -a $OUTPUT_DIR/wordlists/keys.txt
unfurl --unique paths < $OUTPUT_DIR/wordlists/wb.txt    | tee -a $OUTPUT_DIR/wordlists/paths.txt
unfurl --unique keypairs < $OUTPUT_DIR/wordlists/wb.txt | tee -a $OUTPUT_DIR/wordlists/keypairs.txt

cat $OUTPUT_DIR/gospider/* | awk -F' ' '{ print $5 }' | tr '[:punct:]' '\n' | sort -u >  $OUTPUT_DIR/wordlists/w.txt
cat $OUTPUT_DIR/wordlists/paths.txt | tr '[:punct:]' '\n' | sort -u >>  $OUTPUT_DIR/wordlists/w.txt

sort -u $OUTPUT_DIR/wordlists/w.txt > $OUTPUT_DIR/wordlists/wordlist.txt

altdns -i $OUTPUT_DIR/subfinder.txt -o $OUTPUT_DIR/altdns.txt -w $OUTPUT_DIR/wordlists/wordlists.txt

rm $OUTPUT_DIR/wordlists/w.txt

# massdns
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: massdns${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
sleep 3

$TOOLS_DIR/massdns/scripts/subbrute.py $DNS_BRUTE $DOMAIN | massdns -t A -o S -r $RESOLVERS -w $OUTPUT_DIR/massdns-brute.out

cat $OUTPUT_DIR/wordlists/wordlist.txt | massdns -t A -o S -r $RESOLVERS -w $OUTPUT_DIR/massdns-alts.out
cat $OUTPUT_DIR/massdns-brute.out $OUTPUT_DIR/massdns-alts.out | grep -v '127\.0\.0\.1' | sed 's/\s.*//g' | sed 's/\.$//g' | sort -u | tee -a $OUTPUT_DIR/massdns.txt

rm $OUTPUT_DIR/massdns-brute.out $OUTPUT_DIR/massdns-alts.out
sleep 3

# Sort all subdomains into one file
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] Sorting subdomains into one file${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
sleep 3

cat $OUTPUT_DIR/subfinder.txt $OUTPUT_DIR/massdns.txt | lowercase | sort -u | tee -a $OUTPUT_DIR/domains.txt
sleep 3

# dnsx
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: dnsx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#################################################${END}${END}"
sleep 3

cat $OUTPUT_DIR/domains.txt | dnsx -a -resp -verbose -o $OUTPUT_DIR/dnsx.out -r $RESOLVERS
awk -F' ' ' { print $2 } ' $OUTPUT_DIR/dnsx.out | sed -E 's/(\[|\])//g' | sort -u | tee -a $OUTPUT_DIR/ips.txt
awk -F' ' ' { print $1 } ' $OUTPUT_DIR/dnsx.out | sort -u | tee -a $OUTPUT_DIR/all.txt
rm $OUTPUT_DIR/domains.txt
sleep 3

# naabu
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: naabu${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/naabu
naabu -top-ports 1000 -iL $OUTPUT_DIR/all.txt -c 100 -verify -stats -scan-all-ips -timeout 100 -o $OUTPUT_DIR/naabu/naabu-1000.txt
sleep 3

# httpx
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: httpx${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}#########################################${END}${END}"
sleep 3

httpx \
    -title \
	-silent \
    -no-color \
	-no-fallback \
    -o $OUTPUT_DIR/httpx/httpx.out \
	-l $OUTPUT_DIR/naabu/naabu-1000.txt \
	-H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)' \
	-H "X-Remote-IP: 127.0.0.1" \
	-H "X-Remote-Addr: 127.0.0.1" \
	-H "X-Forwarded-For: 127.0.0.1" \
	-H "X-Originating-IP: 127.0.0.1"

awk -F' ' '{ print $1 }' $OUTPUT_DIR/httpx/httpx.out | sort -u | tee -a $OUTPUT_DIR/httpx/httpx.txt
sleep 3

# aquatone
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: aquatone${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
sleep 3

aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone-basic < $OUTPUT_DIR/httpx/httpx.txt
sleep 3

# email
send_email
echo -e "Subject: Screenshots ready for ${DOMAIN} on $(cat /etc/hostname)" >> /tmp/email-template.txt
ls -lah $OUTPUT_DIR/aquatone-basic >> /tmp/email-template.txt
sendmail $EMAIL < /tmp/email-template.txt
rm /tmp/email-template.txt

# corscanner
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: corscanner${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/cors
cors \
	-i $OUTPUT_DIR/httpx/httpx.txt \
	-o $OUTPUT_DIR/cors/cors.json \
	--headers 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)'
sleep 3

# nuclei
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: nuclei${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/nuclei
nuclei \
    -c 100 \
	-stats \
    -headless \
    -severity high \
    -severity critical \
    -l $OUTPUT_DIR/httpx/httpx.txt \
    -t $TOOLS_DIR/nuclei-templates/ \
    -o $OUTPUT_DIR/nuclei/nuclei.out \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)'

grep -oE '\s\[.*' $OUTPUT_DIR/nuclei/nuclei.out | sed 's/^\s//g' | tee -a $OUTPUT_DIR/nuclei/nuclei.txt
rm $OUTPUT_DIR/nuclei/nuclei.out
sleep 3

# find secrets in JS files
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: subdomainizer${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/subdomainizer/
subdomainizer \
	-g \
	-k \
	-d $DOMAIN \
	-o $OUTPUT_DIR/subdomainizer/subs.txt \
	-l $OUTPUT_DIR/gospider/gospider-js.txt \
	-cop $OUTPUT_DIR/subdomainizer/clouds.txt \
	-sop $OUTPUT_DIR/subdomainizer/secrets.txt \
sleep 300

# find endpoints in JS files
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: linkfinder${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}##############################################${END}${END}"
sleep 3

for URL in $(cat $OUTPUT_DIR/gospider/gospider-js.txt)
do
	linkfinder -i $URL -d -o cli | tee -a $OUTPUT_DIR/wordlists/linkfinder.tmp
done

sort -u $OUTPUT_DIR/wordlists/linkfinder.tmp | tee -a $OUTPUT_DIR/linkfinder.txt
rm $OUTPUT_DIR/wordlists/linkfinder.tmp
sleep 300

# email START
send_email
echo -e "Subject: Scans done for ${DOMAIN} on $(cat /etc/hostname)" >> /tmp/email-template.txt
ls -lah $OUTPUT_DIR/ >> /tmp/email-template.txt

echo -e "cors: $(jq .[].url $OUTPUT_DIR/cors/cors.json | sort -u | wc --lines)" >> /tmp/email-template.txt
jq .[].url $OUTPUT_DIR/cors/cors.json | sort -u >> /tmp/email-template.txt
echo -e '' >> /tmp/email-template.txt

echo -e "nuclei: $(wc --lines $OUTPUT_DIR/nuclei/nuclei.txt)" >> /tmp/email-template.txt
cat $OUTPUT_DIR/nuclei/nuclei.txt >> /tmp/email-template.txt
echo -e '' >> /tmp/email-template.txt

sendmail $EMAIL < /tmp/email-template.txt
rm /tmp/email-template.txt
sleep 3
# email END

# masscan
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: masscan${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}###########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/masscan
masscan -v --rate=10000 -p0-65535 --open -oG $OUTPUT_DIR/masscan/masscan-output.gnmap -iL $OUTPUT_DIR/ips.txt
sleep 3

# nmap
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: nmap+naabu${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}########################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/nmap

grep -ioE '[0-9]{1,5}/[a-z]+' $OUTPUT_DIR/masscan/masscan-output.gnmap \
| sort -u \
| awk -F'/' '{ print $1 }' \
| tr '\n' ',' \
| sed 's/,$//g' > $OUTPUT_DIR/nmap/ports.txt

naabu \
	-v \
	-stats \
	-c 100 \
	-verify \
	-timeout 100 \
	-scan-all-ips \
	-iL $OUTPUT_DIR/all.txt \
	-ports-file $OUTPUT_DIR/nmap/ports.txt \
	-nmap-cli "nmap -v -n --script default,vuln,vulners -sV -oA $OUTPUT_DIR/nmap/nmap"
sleep 3

# aquatone
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: aquatone${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
sleep 3

aquatone -chrome-path /usr/bin/chromium-browser -out $OUTPUT_DIR/aquatone -nmap < $OUTPUT_DIR/nmap/nmap.xml
sleep 3

# brutespray
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
echo -e "${MAGENTA}${BOLD}### ${YELLOW}[+] LOADING: brutespray${END}${END}${END}"
echo -e "${MAGENTA}${BOLD}############################################${END}${END}"
sleep 3

mkdir $OUTPUT_DIR/brutespray
brutespray --file $OUTPUT_DIR/nmap/nmap.gnmap --threads 5 --hosts 5 -c -o $OUTPUT_DIR/brutespray/
sleep 3

# email
send_email
echo -e "Subject: Script finished for ${DOMAIN} on $(cat /etc/hostname)" >> /tmp/email-template.txt
ls -lah $OUTPUT_DIR/ >> /tmp/email-template.txt
sendmail $EMAIL < /tmp/email-template.txt
rm /tmp/email-template.txt
