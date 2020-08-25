#!/bin/bash

# Update the system
apt update && apt full-upgrade -y && apt autoremove -y

# Install nmap, masscan, firefox, python, chromium-browser, and go
apt update && apt install -y nmap masscan firefox python3-pip golang chromium-browser python python-pip

# cd into install directory
cd /opt

############
# INSTALLS #
############

# Clone sublist3r
git clone https://github.com/aboul3la/Sublist3r.git
cd Sublist3r/
pip install -r requirements.txt
ln -sf /opt/Sublist3r/sublist3r.py /usr/bin/sublist3r

# Go back to install directory
cd /opt

# Clone dirsearch
git clone https://github.com/maurosoria/dirsearch.git
ln -sf /opt/dirsearch/dirsearch.py /usr/bin/dirsearch

# Go back to install directory
cd /opt

# Go back to install directory
cd /opt

# Install massdns
git clone https://github.com/blechschmidt/massdns.git
cd massdns && make

# Install amass
snap install amass && sudo snap refresh

# Finished
echo "[+] Tools installed into: /opt"
echo "[+] TODO: install aquatone and subfinder"
echo "[+] Done."
