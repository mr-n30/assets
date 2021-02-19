#!/bin/bash

INSTALL_DIR=/opt/tools
mkdir $INSTALL_DIR
cd ~

# Install brutespray and medusa
sudo apt install medusa brutespray

# Install dirsearch
sudo git clone https://github.com/maurosoria/dirsearch.git && \
	sudo mv dirsearch $INSTALL_DIR && \
	sudo ln -sf $INSTALL_DIR/dirsearch/dirsearch.py /usr/bin/dirsearch

# Install corscanner
sudo git clone https://github.com/chenjj/CORScanner.git && \
    sudo mv CORScanner $INSTALL_DIR && \
    sudo cd $INSTALL_DIR/CORScanner/ && \
    sudo pip3 install -r requirements.txt && \
    sudo ln -sf $INSTALL_DIR/CORScanner/cors_scan.py /usr/bin/cors

# Install unfurl
sudo go get -u github.com/tomnomnom/unfurl && \
	sudo mv ~/go ~/unfurl && \
	sudo mv ~/unfurl $INSTALL_DIR && \
	sudo ln -sf $INSTALL_DIR/unfurl/bin/unfurl /usr/bin/unfurl

# Install nuclei
    sudo mkdir $INSTALL_DIR/nuclei && \
	sudo nuclei -update-directory $INSTALL_DIR/nuclei/ -update-templates && \

# Install linkfinder
sudo git clone https://github.com/GerbenJavado/LinkFinder.git && \
	sudo mv LinkFinder $INSTALL_DIR && \
	sudo cd $INSTALL_DIR/LinkFinder && \
	sudo python3 setup.py install && \
	sudo pip3 install -r requirements.txt && \
	sudo ln -sf $INSTALL_DIR/LinkFinder/linkfinder.py /usr/bin/linkfinder

# Install smuggler
sudo git clone https://github.com/defparam/smuggler.git && \
    sudo mv smuggler $INSTALL_DIR && \
    sudo ln -sf $INSTALL_DIR/smuggler/smuggler.py /usr/bin/smuggler

# Finished
cd $INSTALL_DIR
echo "[+] Tools installed into: $INSTALL_DIR"
echo "[+] Done."
