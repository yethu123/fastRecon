# fastRecon

**Overview:**

This script automates a fast recon framework for gathering information about a target domain. It utilizes various tools for subdomain discovery, live host enumeration, potential vulnerability identification, and additional intelligence gathering.

**Note:** This script is for educational purposes only and should not be used without permission on domains you don't own. Misusing this script for malicious purposes is illegal and unethical.

**Requirements:**

**Operating System:** Linux-based systems (e.g., Ubuntu, Debian, Kali)

**Tools:**
 1. assetfinder 
 2. subfinder 
 3. httpx 
 4. waybackurls 
 5. gau (GetAllUrls) 
 6. nuclei 
 7. anew
 8. gf 
 9. katana 
 10. dalfox 
 11. notify 
 12. JSParser 
 13. Sublist3r 
 14. teh_s3_bucketeers 
 15. wpscan
 16. dirsearch 
 17. lazys3 
 18. virtual-host-discovery 
 19. sqlmap 
 20. knock.py 
 21. lazyrecon
 22. nmap 
 23. massdns 
 24. asnlookup 
 25. httprobe 
 26. unfurl 
 27. crtndstry 
 28. SecLists 
 29. wafw00f
 30. gobuster 
 31. feroxbuster

**Installation:**

Follow the installation instructions for each tool on their respective websites or repositories. Some tools may require additional dependencies, like Python and Go.
**Environmaent**
```
#go
export GOROOT=/usr/local/go
export GOPATH=/root/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
```
**quick install :**

```
go install github.com/tomnomnom/assetfinder@latest
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install -v github.com/tomnomnom/anew@latest
go install -v github.com/tomnomnom/gf@latest
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/lc/gau/v2/cmd/gau@latest
sudo apt install assetfinder
sudo apt-get install -y wafw00f
sudo apt-get install -y dirsearch
```
## GF Installation

Follow these steps to install and configure `gf`:

### **1. Create the GF Configuration Directory**

```bash
mkdir ~/.gf
```

### **2. Clone and Copy GF Patterns**

```bash
git clone https://github.com/1ndianl33t/Gf-Patterns.git ~/tools/
cp ~/tools/Gf-Patterns/*.json ~/.gf/
```

### **3. Clone and Copy Default GF Examples**

```bash
git clone https://github.com/tomnomnom/gf.git ~/tools/
cp ~/tools/gf/examples/*.json ~/.gf/
```

### **4. Verify GF Installation**

Run the following command to check if `gf` is working:

```bash
gf -list
```

This should display the available patterns.

Now, you are ready to use `gf` for pattern-based filtering! 🚀


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
