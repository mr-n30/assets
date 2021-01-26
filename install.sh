#!/bin/bash

INSTALL_DIR=/opt/
cd ~

# Update the system
sudo apt update && 
	sudo add-apt-repository ppa:longsleep/golang-backports && \
	sudo apt update && \
	sudo apt install -y nmap masscan make firefox python3-pip python-pip python chromium-browser ssmtp jq whois libpq-dev golang-go && \
	sudo apt -y autoremove

# Install amass
export GO111MODULE=on && \
	go get -v github.com/OWASP/Amass/v3/... && \
	mv ~/go ~/amass && \
	mv ~/amass $INSTALL_DIR && \
	ln -sf $INSTALL_DIR/amass/bin/amass /usr/bin/amass

# Install subfinder
export GO111MODULE=on && \
	go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder && \
	mv ~/go ~/subfinder && \
	mv ~/subfinder $INSTALL_DIR/ && \
	ln -sf $INSTALL_DIR/subfinder/bin/subfinder /usr/bin/subfinder

# Install sublist3r
git clone https://github.com/aboul3la/Sublist3r.git && \
	mv Sublist3r/ $INSTALL_DIR && \
	pip install -r $INSTALL_DIR/Sublist3r/requirements.txt && \
	ln -sf $INSTALL_DIR/Sublist3r/sublist3r.py /usr/bin/sublist3r

# Install massdns
git clone https://github.com/blechschmidt/massdns.git && 
	cd massdns/ && \
	make && \
	ln -sf /opt/massdns/bin/massdns /usr/bin/massdns

# Install ffuf
go get -u github.com/ffuf/ffuf && \
	mv ~/go ~/fuff && \
	mv ~/ffuf /opt/ffuf && \
	ln -sf /opt/ffuf/bin/ffuf /usr/bin/ffuf

# Install dirsearch
git clone https://github.com/maurosoria/dirsearch.git \
	&& cd dirsearch

# Install aquatone
mkdir $INSTALL_DIR/aquatone && \
	wget -P $INSTALL_DIR/aquatone/ https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip && \
	unzip -d $INSTALL_DIR/aquatone/ $INSTALL_DIR/aquatone/aquatone_linux_amd64_1.7.0.zip && \
	ln -sf /$INSTALL_DIR/aquatone/aquatone /usr/bin/aquatone

# Install nuclei
GO111MODULE=on && \
	go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei && \
	mv ~/go ~/nuclei && \
	mv ~/nuclei $INSTALL_DIR && \
	ln -sf ~/$INSTALL_DIR/nuclei/bin/nuclei /usr/bin/nuclei

# Finished
echo "[+] Tools installed into: /opt"
echo "[+] Done."
