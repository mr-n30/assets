#!/bin/bash

INSTALL_DIR=/opt/tools
mkdir $INSTALL_DIR
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
git clone https://github.com/blechschmidt/massdns.git && \
	mv massdns $INSTALL_DIR && \
	cd $INSTALL_DIR/massdns/ && \
	make && \
	ln -sf $INSTALL_DIR/massdns/bin/massdns /usr/bin/massdns

cd ~

# Install ffuf
go get -u github.com/ffuf/ffuf && \
	mv ~/go ~/ffuf && \
	mv ~/ffuf $INSTALL_DIR && \
	ln -sf $INSTALL_DIR/ffuf/bin/ffuf /usr/bin/ffuf

# Install dirsearch
git clone https://github.com/maurosoria/dirsearch.git && \
	mv dirsearch $INSTALL_DIR && \
	ln -sf $INSTALL_DIR/dirsearch/dirsearch.py /usr/bin/dirsearch

# Instal gobuster
go get -u github.com/OJ/gobuster && \
	mv ~/go ~/gobuster && \
	mv ~/gobuster $INSTALL_DIR && \
	ln -sf $INSTALL_DIR/gobuster/bin/gobuster /usr/bin/gobuster

# Install aquatone
mkdir $INSTALL_DIR/aquatone && \
	wget -P $INSTALL_DIR/aquatone/ https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip && \
	unzip -d $INSTALL_DIR/aquatone/ $INSTALL_DIR/aquatone/aquatone_linux_amd64_1.7.0.zip && \
	ln -sf $INSTALL_DIR/aquatone/aquatone /usr/bin/aquatone

# Install corscanner
pip install cors

# Install unfurl
go get -u github.com/tomnomnom/unfurl && \
	mv ~/go ~/unfurl && \
	mv ~/unfurl $INSTALL_DIR && \
	ln -sf $INSTALL_DIR/unfurl/bin/unfurl /usr/bin/unfurl

# Install waybackurls
go get -u github.com/tomnomnom/waybackurls && \
	mv ~/go ~/waybackurls && \
	mv ~/waybackurls $INSTALL_DIR && \
	ln -sf $INSTALL_DIR/waybackurls/bin/waybackurls /usr/bin/waybackurls

# Install httpx
export GO111MODULE=on && \
	go get -v github.com/projectdiscovery/httpx/cmd/httpx && \
	mv ~/go ~/httpx && \
	mv ~/httpx $INSTALL_DIR/ && \
	ln -sf $INSTALL_DIR/httpx/bin/httpx /usr/bin/httpx

# Install nuclei
export GO111MODULE=on && \
	go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei && \
	mv ~/go ~/nuclei && \
	mv ~/nuclei $INSTALL_DIR && \
	$INSTALL_DIR/nuclei/bin/nuclei -update-directory $INSTALL_DIR/nuclei/ -update-templates && \
	ln -sf $INSTALL_DIR/nuclei/bin/nuclei /usr/bin/nuclei

# Install linkfinder
git clone https://github.com/GerbenJavado/LinkFinder.git && \
	mv LinkFinder $INSTALL_DIR && \
	cd $INSTALL_DIR/LinkFinder && \
	python3 setup.py install && \
	pip3 install -r requirements.txt && \
	ln -sf $INSTALL_DIR/LinkFinder/linkfinder.py /usr/bin/linkfinder

cd $INSTALL_DIR

# Finished
echo "[+] Tools installed into: $INSTALL_DIR"
echo "[+] Done."
