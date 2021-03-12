#!/bin/bash

INSTALL_DIR=/opt/tools

rm -rf $INSTALL_DIR/go

# Install gopackages
export GO111MODULE=on
go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
go get -v github.com/projectdiscovery/dnsx/cmd/dnsx
go get -v github.com/projectdiscovery/httpx/cmd/httpx
go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
go get -u github.com/ffuf/ffuf
go get -u github.com/tomnomnom/unfurl
go get -u github.com/tomnomnom/waybackurls
go get -u github.com/jaeles-project/gospider
go get -v github.com/projectdiscovery/naabu/v2/cmd/naabu

# Create links for go packages
mv ~/go $INSTALL_DIR
ln -sf $INSTALL_DIR/go/bin/subfinder /usr/bin/subfinder
ln -sf $INSTALL_DIR/go/bin/dnsx /usr/bin/dnsx
ln -sf $INSTALL_DIR/go/bin/httpx /usr/bin/httpx
ln -sf $INSTALL_DIR/go/bin/nuclei /usr/bin/nuclei
ln -sf $INSTALL_DIR/go/bin/ffuf /usr/bin/ffuf
ln -sf $INSTALL_DIR/go/bin/unfurl /usr/bin/unfurl
ln -sf $INSTALL_DIR/go/bin/waybackurls /usr/bin/waybackurls
ln -sf $INSTALL_DIR/go/bin/gospider /usr/bin/gospider
ln -sf $INSTALL_DIR/go/bin/naabu /usr/bin/naabu

# Set nuclei templates directory
mkdir $INSTALL_DIR/nuclei-templates
nuclei -update-directory $INSTALL_DIR/ -update-templates
