# fastRecon

**Overview:**

This script automates a fast recon framework for gathering information about a target domain. It utilizes various tools for subdomain discovery, live host enumeration, potential vulnerability identification, and additional intelligence gathering.

**Note:** This script is for educational purposes only and should not be used without permission on domains you don't own. Misusing this script for malicious purposes is illegal and unethical.

**Requirements:**

**Operating System:** Linux-based systems (e.g., Ubuntu, Debian, Kali)

**Tools:**

- **Subfinder:** [https://github.com/projectdiscovery/subfinder](https://github.com/projectdiscovery/subfinder)
- **Assetfinder:** [https://github.com/tomnomnom/assetfinder](https://github.com/tomnomnom/assetfinder)
- **HTTPX:** [https://github.com/projectdiscovery/httpx](https://github.com/projectdiscovery/httpx)
- **Waybackurls:** [https://github.com/tomnomnom/waybackurls](https://github.com/tomnomnom/waybackurls)
- **Gau:** [https://github.com/lc/gau](https://github.com/lc/gau)
- **GF (GrepFuzz):** [https://github.com/tomnomnom/gf](https://github.com/tomnomnom/gf)
- **Aquatone:** [https://github.com/michenriksen/aquatone](https://github.com/michenriksen/aquatone)
- **Wafw00f:** [https://github.com/EnableSecurity/wafw00f](https://github.com/EnableSecurity/wafw00f)
- **Dirsearch:** [https://github.com/maurosoria/dirsearch](https://github.com/maurosoria/dirsearch)
- **Nuclei:** [https://github.com/projectdiscovery/nuclei-templates](https://github.com/projectdiscovery/nuclei-templates)
- **Afrog:** [https://github.com/zan8in/afrog](https://github.com/zan8in/afrog)

**Installation:**

Follow the installation instructions for each tool on their respective websites or repositories. Some tools may require additional dependencies, like Python and Go.
**quick install :**

```
go get -u github.com/tomnomnom/assetfinder
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/tomnomnom/gf@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
apt-get install -y wafw00f
apt-get install -y dirsearch
```

**Usage:**

```jsx
./fast_recon.sh -d <target_domain> [options]

Options:
  -d <target_domain>     Required - Target domain to scan.
  -e <exclude_domain>   Optional - Domain to exclude from subdomain discovery.
  -a                    Optional - Run Aquatone for DNS profiling.
  -w                    Optional - Run Wafw00f for WAF detection.
  -s <wordlist>         Optional - Path to wordlist for Dirsearch.
  -n                    Optional - Run Nuclei for vulnerability scanning.
```

**Additional Notes:**

- Replace `<target_domain>` with the actual domain you want to scan.
- Be aware of the legal and ethical implications of using this script.
- Review the configuration options in the script to customize your scan.
- The script will create a directory named `fastRecon_<date>` within the current directory to store results.
- Consider the limitations of each tool and use additional techniques for a comprehensive assessment.

**Disclaimer:**

The author is not responsible for any misuse of this script. By using this script, you acknowledge that you understand and agree to these terms.

**Security Note:**

This script provides powerful tools for automated recon. Remember to use it responsibly and ethically, respecting legal and privacy obligations. Always obtain proper authorization before scanning any domain that you do not own or manage.
