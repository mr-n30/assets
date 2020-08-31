#!/bin/bash

# Update the system
sudo apt update \
&& sudo apt full-upgrade -y \
&& sudo apt autoremove -y \
&& sudo apt install -y nmap masscan make firefox python3-pip python-pip python chromium-browser ssmtp jq whois \
&& sleep 5;

############
# INSTALLS #
############

# cd into install directory
cd /opt;

# Clone sublist3r
git clone https://github.com/aboul3la/Sublist3r.git \
&& cd Sublist3r/ \
&& pip install -r requirements.txt \
&& ln -sf /opt/Sublist3r/sublist3r.py /usr/bin/sublist3r \
&& sleep 1;

# Go back to install directory
cd /opt;

# Clone geturls
git clone https://github.com/mr-n30/geturls.git \
&& cd geturls/ \
&& pip install -r requirementst.txt \
&& sleep 1;

# Go back to install directory
cd /opt;

# Install massdns
git clone https://github.com/blechschmidt/massdns.git \
&& cd massdns \
&& make \
&& ln -sf /opt/massdns/bin/massdns /usr/bin/massdns \
&& sleep 1;

# Install amass
snap install amass \
&& sudo snap refresh \
&& sleep 1;

# Install altdns
pip install py-altdns \
&& sleep 1;

# Install ffuf
snap install --classic --channel=1.11/stable go
go get github.com/ffuf/ffuf \
&& mv ~/go/ ~/ffuf/ \
&& mv ~/ffuf/ /opt/ \
&& ln -sf /opt/ffuf/bin/ffuf /usr/bin/ffuf \
&& sleep 1;

# Finished
echo "[+] Tools installed into: /opt";
echo "[+] Done.";
