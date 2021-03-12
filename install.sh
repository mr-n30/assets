#!/bin/bash

INSTALL_DIR=/opt/tools
mkdir $INSTALL_DIR
cd ~

# Update the system
sudo apt update &&
	sudo add-apt-repository ppa:longsleep/golang-backports -y && \
	sudo apt update && \
	sudo apt install -y nmap masscan make gcc firefox python3-pip python-pip python chromium-browser ssmtp jq whois libpq-dev golang-go medusa unzip openssl libssl-dev libpcap0.8 libpcap0.8-dev libpcap-dev && \
	sudo apt -y autoremove

# Install massdns
git clone https://github.com/blechschmidt/massdns.git && \
	mv massdns $INSTALL_DIR && \
	cd $INSTALL_DIR/massdns/ && \
	make && \
	ln -sf $INSTALL_DIR/massdns/bin/massdns /usr/bin/massdns

# Install aquatone
mkdir $INSTALL_DIR/aquatone && \
	wget -P $INSTALL_DIR/aquatone/ https://github.com/michenriksen/aquatone/releases/download/v1.7.0/aquatone_linux_amd64_1.7.0.zip && \
	unzip -d $INSTALL_DIR/aquatone/ $INSTALL_DIR/aquatone/aquatone_linux_amd64_1.7.0.zip && \
	ln -sf $INSTALL_DIR/aquatone/aquatone /usr/bin/aquatone

# Install corscanner
git clone https://github.com/chenjj/CORScanner.git && \
    mv CORScanner $INSTALL_DIR && \
    cd $INSTALL_DIR/CORScanner/ && \
    pip3 install -r requirements.txt && \
    ln -sf $INSTALL_DIR/CORScanner/cors_scan.py /usr/bin/cors

# Install linkfinder
git clone https://github.com/GerbenJavado/LinkFinder.git && \
	mv LinkFinder $INSTALL_DIR && \
	cd $INSTALL_DIR/LinkFinder && \
	python3 setup.py install && \
	pip3 install -r requirements.txt && \
	ln -sf $INSTALL_DIR/LinkFinder/linkfinder.py /usr/bin/linkfinder

# Install smuggler
git clone https://github.com/defparam/smuggler.git && \
    mv smuggler $INSTALL_DIR && \
    ln -sf $INSTALL_DIR/smuggler/smuggler.py /usr/bin/smuggler

# Install brutespray
git clone https://github.com/x90skysn3k/brutespray.git && \
    mv brutespray /opt/tools && \
    cd /opt/tools/brutespray && \
    pip install -r requirements.txt && \
    pip3 install -r requirements.txt && \
    ln -sf /opt/tools/brutespray.py /usr/bin/brutespray

# Install nmap
git clone https://github.com/nmap/nmap.git && \
    mv nmap /opt/tools/ && \
    cd /opt/tools/nmap && \
    ./configure && \
    make && \
    make install

# Install masscan
git clone https://github.com/robertdavidgraham/masscan.git && \
    mv masscan /opt/tools && \
    cd /opt/tools/masscan && \
    make && \
    make install

# Install subdomainizer
git clone https://github.com/nsonaniya2010/SubDomainizer.git && \
    mv SubDomainizer /opt/tools && \
    cd /opt/tools/SubDomainizer && \
    pip install -r requirements.txt && \
    pip3 install -r requirements.txt && \
    ln -sf /opt/tools/SubDomainizer /usr/bin/subdomainizer

# Install fresh dns resolvers list
git clone https://github.com/BonJarber/fresh-resolvers.git && \
    mv fresh-resolvers /opt/tools

# Install altdns
git clone https://github.com/infosec-au/altdns.git $INSTALL_DIR/altdns && \
cd $INSTALL_DIR/altdns && \
pip install -r requirements.txt && \
pip3 install -r requirements.txt && \
python3 setup.py install

# lowercase.py
ln -sf $INSTALL_DIR/../assets/lowercase.py /usr/bin/lowercase

# Finished
echo "[+] Tools installed into: $INSTALL_DIR"
echo "[+] Done."
sleep 3
