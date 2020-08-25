#!/bin/bash

# Update the system
apt update && apt full-upgrade -y && apt autoremove -y
sleep 3

############
# INSTALLS #
############

# Install from repo
apt install -y nmap masscan firefox python3-pip golang chromium-browser python ssmtp

# cd into install directory
cd /opt

# Clone sublist3r
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r/
pip install -r requirements.txt
ln -sf /opt/Sublist3r/sublist3r.py /usr/bin/sublist3r

# Go back to install directory
cd /opt

# Go back to install directory
cd /opt

# Clone geturls
git clone https://github.com/mr-n30/geturls
ln -sf /opt/geturls/geturls.py /usr/bin/geturls

# Go back to install directory
cd /opt

# Install massdns
git clone https://github.com/blechschmidt/massdns.git
cd massdns && make

# Install amass
snap install amass && sudo snap refresh

# Install altdns
pip3 install py-altdns

# Install ffuf
go get github.com/ffuf/ffuf
mv ~/go/ ~/ffuf/ && mv ~/ffuf/ /opt/ && ln -sf /opt/ffuf/bin/ffuf /usr/bin/ffuf

# Finished
echo "[+] Tools installed into: /opt"
echo "[+] Done."