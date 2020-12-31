# assets.sh
Bash script used to automate asset discovery when doing recon. Output will be saved in `argv[1]/argv[2]`.

## Tools used:
- [amass](https://github.com/OWASP/Amass)
- [sublist3r](https://github.com/aboul3la/Sublist3r)
- [subfinder](https://github.com/projectdiscovery/subfinder)
- [massdns](https://github.com/blechschmidt/massdns/tree/v0.2)
- [nmap](https://nmap.org/)
- [masscan](https://github.com/robertdavidgraham/masscan)
- [aquatone](https://github.com/michenriksen/aquatone)
- [nuclei](https://github.com/projectdiscovery/nuclei)
- [httprobe](https://github.com/tomnomnom/httprobe)

## Installation:
```bash
# chmod +x setup.sh && ./setup.sh
```

## Usage:
```bash
# chmod +x assets.sh
# ./assets.sh <directory> <domain>
```
