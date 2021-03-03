#!/bin/bash

INSTALL_DIR=/opt/tools

rm -rf $INSTALL_DIR/go

# Install gopackages
export GO111MODULE=on
go get -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder
go get -v github.com/OWASP/Amass/v3/...
go get -v github.com/projectdiscovery/dnsx/cmd/dnsx
go get -v github.com/projectdiscovery/httpx/cmd/httpx
go get -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei
go get -u github.com/ffuf/ffuf
go get -u github.com/tomnomnom/unfurl
go get -u github.com/tomnomnom/waybackurls
go get -u github.com/jaeles-project/gospider

# Create links for go packages
mv ~/go $INSTALL_DIR
ln -sf $INSTALL_DIR/go/bin/subfinder /usr/bin/subfinder
ln -sf $INSTALL_DIR/go/bin/amass /usr/bin/amass
ln -sf $INSTALL_DIR/go/bin/dnsx /usr/bin/dnsx
ln -sf $INSTALL_DIR/go/bin/httpx /usr/bin/httpx
ln -sf $INSTALL_DIR/go/bin/nuclei /usr/bin/nuclei
ln -sf $INSTALL_DIR/go/bin/ffuf /usr/bin/ffuf
ln -sf $INSTALL_DIR/go/bin/unfurl /usr/bin/unfurl
ln -sf $INSTALL_DIR/go/bin/waybackurls /usr/bin/waybackurls
ln -sf $INSTALL_DIR/go/bin/gospider /usr/bin/gospider

# Set nuclei templates directory
nuclei -update-directory $INSTALL_DIR/ -update-templates
