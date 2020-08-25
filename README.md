# assets.sh
Bash script used to automate asset discovery when doing recon. Output will be created and saved in: `~/targets/<domain>`.

Consider the following script to install all tools and dependencies needed for this script: https://github.com/mr-n30/server_setup_script

# Tools used:
- [amass](https://github.com/OWASP/Amass)
- [sublist3r](https://github.com/aboul3la/Sublist3r)
- [subfinder](https://github.com/subfinder/subfinder)
- [massdns](https://github.com/blechschmidt/massdns/tree/v0.2)
- [nmap](https://nmap.org/)
- [aquatone](https://github.com/michenriksen/aquatone)

# Installation:
```bash
# chmod +x setup.sh && ./setup.sh
```

# Usage:
```bash
# chmod +x assets.sh
# ./assets.sh <domain>
```
