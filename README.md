# assets.sh
Bash script used to automate asset discovery when doing recon. Output will be saved in `argv[2]`.

## Tools used:
- [amass](https://github.com/OWASP/Amass)
- [sublist3r](https://github.com/aboul3la/Sublist3r)
- [subfinder](https://github.com/projectdiscovery/subfinder)
- [massdns](https://github.com/blechschmidt/massdns/tree/v0.2)
- [nmap](https://nmap.org/)
- [geturls](https://github.com/mr-n30/geturls)

## Installation:
```bash
# chmod +x setup.sh && ./setup.sh
```

## Usage:
```bash
# chmod +x assets.sh
# ./assets.sh <domain> <directory_to_save_output>
```
