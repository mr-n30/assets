#!/bin/bash

# variables
EMAIL=$2
RESOLVERS=/opt/tools/fresh-resolvers/resolvers.txt
TOOLS_DIR=/opt/tools
NMAP_TOP_PORTS=/opt/p/nmap-top-1000-ports.txt
SUBFINDER_CONFIG=/opt/p/config.yaml

# Update resolvers
cd $TOOLS_DIR/fresh-resolvers/ && git pull
sleep 3

# Create install directory
mkdir -p $OUTPUT_DIR/scan
OUTPUT_DIR=$1/scan
sleep 3

# Set the domain
DOMAIN=$(cat ~/domain.txt)

# subfinder
subfinder -d $DOMAIN -o $OUTPUT_DIR/subfinder-new.txt -all -config $SUBFINDER_CONFIG
sleep 3

# Check for diffs in subdomains
echo -e "[*] Checking for differences in subfinder..."
mkdir $OUTPUT_DIR/diff
! diff $OUTPUT_DIR/subfinder-old.txt $OUTPUT_DIR/subfinder-new.txt && \
	diff $OUTPUT_DIR/subfinder-old.txt $OUTPUT_DIR/subfinder-new.txt | grep '^>' | awk -F'>' '{ print $2 }' | sed 's/^\s//g' > $OUTPUT_DIR/diff/sub-diff.txt && \
    echo -e "To: ${EMAIL}" >> /tmp/email-template.txt && \
    echo -e "From: $USER@$(cat /etc/hostname)" >> /tmp/email-template.txt && \
    echo -e "Content-Type: text/plain;" >> /tmp/email-template.txt && \
    echo -e "Subject: Differences found in subdomains for domain ${DOMAIN} on $(cat /etc/hostname)" >> /tmp/email-template.txt && \
    cat $OUTPUT_DIR/diff/sub-diff.txt >> /tmp/email-template.txt && \
    sendmail $EMAIL < /tmp/email-template.txt
mv $OUTPUT_DIR/subfinder-new.txt $OUTPUT_DIR/subfinder-old.txt
rm /tmp/email-template.txt
sleep 3

# dnsx
cat $OUTPUT_DIR/subfinder-old.txt | sort -u | dnsx -a -resp -verbose -o $OUTPUT_DIR/dnsx.out -r $RESOLVERS
awk -F' ' ' { print $2 } ' $OUTPUT_DIR/dnsx.out | sed -E 's/(\[|\])//g' | sort -u | tee -a $OUTPUT_DIR/ips.txt
awk -F' ' ' { print $1 } ' $OUTPUT_DIR/dnsx.out | sort -u | tee -a $OUTPUT_DIR/all.txt
sleep 3

# httpx
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
sleep 3

# nuclei
nuclei \
    -c 100 \
    -headless \
    -severity medium \
    -severity high \
    -severity critical \
    -l $OUTPUT_DIR/httpx.txt \
    -o $OUTPUT_DIR/nuclei-new.out \
    -H 'User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_6_8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36 - (BUGCROWD: n30 / HACKERONE: mr_n30)'
grep -oE '\s\[.*' $OUTPUT_DIR/nuclei-new.out | sed 's/^\s//g' | tee -a $OUTPUT_DIR/nuclei-new.txt
rm $OUTPUT_DIR/nuclei-new.out
sleep 3

# Check for diffs in nuclei
echo -e "[*] Checking for differences in nuclei..."
! diff $OUTPUT_DIR/nuclei-old.txt $OUTPUT_DIR/nuclei-new.txt && \
	diff $OUTPUT_DIR/nuclei-old.txt $OUTPUT_DIR/nuclei-new.txt | grep '^>' | awk -F'>' '{ print $2 }' | sed 's/^\s//g' > $OUTPUT_DIR/diff/nuclei-diff.txt && \
    echo -e "To: ${EMAIL}" >> /tmp/email-template.txt && \
    echo -e "From: $USER@$(cat /etc/hostname)" >> /tmp/email-template.txt && \
    echo -e "Content-Type: text/plain;" >> /tmp/email-template.txt && \
    echo -e "Subject: Differences found in nuclei for domain ${DOMAIN} on $(cat /etc/hostname)" >> /tmp/email-template.txt && \
    cat $OUTPUT_DIR/diff/nuclei-diff.txt >> /tmp/email-template.txt && \
    sendmail $EMAIL < /tmp/email-template.txt
mv $OUTPUT_DIR/nuclei-new.txt $OUTPUT_DIR/nuclei-old.txt
rm /tmp/email-template.txt
sleep 3

echo "[+] Done..."
sleep 3

