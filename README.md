# assets.sh
Bash script used to automate doing recon.

## Tools used:
- [amass](https://github.com/OWASP/Amass)
- [subfinder](https://github.com/projectdiscovery/subfinder)
- [sublist3r](https://github.com/aboul3la/Sublist3r)
- [massdns](https://github.com/blechschmidt/massdns/tree/v0.2)
- [nmap](https://nmap.org/)
- [masscan](https://github.com/robertdavidgraham/masscan)
- [aquatone](https://github.com/michenriksen/aquatone)
- [nuclei](https://github.com/projectdiscovery/nuclei)
- [httprobe](https://github.com/tomnomnom/httprobe)
- [httpx](https://github.com/projectdiscovery/httpx)
- [waybackurls](https://github.com/tomnomnom/waybackurls)
- [linkfinder](https://github.com/GerbenJavado/LinkFinder)
- [ffuf](https://github.com/ffuf/ffuf)
- [corscanner](https://github.com/chenjj/CORScanner)
- [unfurl](https://github.com/tomnomnom/unfurl)

## Installation:
```bash
chmod +x install.sh; ./install.sh
```
## Before using 
* Make sure to set up your SSMTP config file
* Modify the variable SECLISTS in the script
* Modify the variable WORDLIST in the script

## Usage:
```bash
chmod +x assets.sh; ./assets.sh -h
```
