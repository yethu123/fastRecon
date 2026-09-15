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
target_domain=""
domain_list_file=""
run_aquatone=false
run_wafw00f=false
run_nuclei=false
run_dirsearch=false
subdomainThreads=30
dirsearchThreads=30
dirsearchWordlist="/usr/share/dirb/wordlists/common.txt"

# Parse command-line arguments
while getopts ":d:e:awns:l:" opt; do
    case $opt in
        d) target_domain="$OPTARG" ;;
        l) domain_list_file="$OPTARG" ;;
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

# Usage message, reused for validation errors below
usage() {
    echo -e "${RED}${LARGE}Usage: $0 -d <target_domain> [-e <exclude_domain>] [-a] [-w] [-s <wordlist_path>] [-n]${RESET}" >&2
    echo -e "${RED}${LARGE}   or: $0 -l <domain_list_file> [-e <exclude_domain>] [-a] [-w] [-s <wordlist_path>] [-n]${RESET}" >&2
}

# Validate required parameters: exactly one of -d or -l must be provided
if [ -z "$target_domain" ] && [ -z "$domain_list_file" ]; then
    usage
    exit 1
fi

if [ -n "$target_domain" ] && [ -n "$domain_list_file" ]; then
    echo -e "${RED}${LARGE}Use either -d <target_domain> or -l <domain_list_file>, not both.${RESET}" >&2
    exit 1
fi

# Build the list of domains to process
declare -a domain_list
if [ -n "$domain_list_file" ]; then
    if [ ! -f "$domain_list_file" ]; then
        echo -e "${RED}${LARGE}Domain list file not found: $domain_list_file${RESET}" >&2
        exit 1
    fi
    # Strip blank lines, comment lines (#...), and surrounding whitespace/CR
    mapfile -t domain_list < <(sed -e 's/\r$//' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$domain_list_file" \
        | grep -v '^\s*$' | grep -v '^\s*#')
    if [ "${#domain_list[@]}" -eq 0 ]; then
        echo -e "${RED}${LARGE}Domain list file is empty: $domain_list_file${RESET}" >&2
        exit 1
    fi
else
    domain_list=("$target_domain")
fi

# Function to store manual commands
manual_command() {
   echo -e "${YELLOW}${LARGE}Saving manual commands...${RESET}"
    local manual_rawcommand="$(curl -s https://raw.githubusercontent.com/yethu123/fastRecon/refs/heads/main/command_manual.txt)"
    echo "$manual_rawcommand" > "$fast_recon_dir/manual_rawcommand.txt"
    sed "s|reconDir|$fast_recon_dir|g"  "$fast_recon_dir/manual_rawcommand.txt" > "$fast_recon_dir/manual_command1.txt"
    rm "$fast_recon_dir/manual_rawcommand.txt"
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
    cat "$fast_recon_dir/subdomains/subdomains.txt" | httpx -t 50 -p 80,443,8000,8080,8443 | anew "$fast_recon_dir/httpx_raw.txt"
    echo "cat \"$fast_recon_dir/subdomains/subdomains.txt\" | httpx -t 50 -p 80,443,8000,8080,8443 | anew \"$fast_recon_dir/httpx.txt\"" >> "$fast_recon_dir/commands_log.txt"
    echo -e "${GREEN}${LARGE}HTTP enumeration completed.${RESET}"
    cat "$fast_recon_dir/httpx_raw.txt" | grep "$target_domain" | anew "$fast_recon_dir/httpx.txt"
}

# Function to run Wayback URLs
run_waybackurls() {
    # Print the "Running Wayback URLs..." message
    echo -e "${YELLOW}${LARGE}Running gau...${RESET}"

    # Run 'gau' on the list of URLs from 'httpx.txt', filter by target domain, and save results to 'gau.txt'
    cat "$fast_recon_dir/httpx.txt" | waybackurls | grep "$target_domain" | anew "$fast_recon_dir/contents/gau.txt"
    #cat "$fast_recon_dir/httpx.txt" | gau | grep "$target_domain" | anew "$fast_recon_dir/contents/gau.txt"

    # Log the 'gau' command to the commands_log.txt
    echo "cat \"$fast_recon_dir/httpx.txt\" | waybackurls | grep \"$target_domain\" | anew \"$fast_recon_dir/contents/gau.txt\"" >> "$fast_recon_dir/commands_log.txt"

    #echo "cat \"$fast_recon_dir/httpx.txt\" | gau | grep \"$target_domain\" | anew \"$fast_recon_dir/contents/gau.txt\"" >> "$fast_recon_dir/commands_log.txt"
    echo -e "${YELLOW}${LARGE}Running katana...${RESET}"
    # Run 'katana' to extract URLs and output to 'katana.txt'
    katana -list "$fast_recon_dir/httpx.txt" -f url -d 10 -o "$fast_recon_dir/contents/katana.txt"

    # Log the 'katana' command to the commands_log.txt
    echo "katana -list \"$fast_recon_dir/httpx.txt\" -f url -d 10 -o \"$fast_recon_dir/contents/katana.txt\"" >> "$fast_recon_dir/commands_log.txt"

    # Combine the URLs from 'gau.txt' and 'katana.txt' and save them into 'waybackurls.txt'
    cat "$fast_recon_dir/contents/gau.txt" "$fast_recon_dir/contents/katana.txt" | anew "$fast_recon_dir/waybackurls.txt"

    # Print success message
    echo -e "${GREEN}${LARGE} URLs captured with gau and katana.${RESET}"
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

# Execute reconnaissance tasks for each domain in domain_list
total_domains="${#domain_list[@]}"
domain_index=0

for target_domain in "${domain_list[@]}"; do
    domain_index=$((domain_index + 1))
    echo -e "${YELLOW}${LARGE}=== [$domain_index/$total_domains] Starting recon on: $target_domain ===${RESET}"

    # Define and create reconnaissance directory structure for this domain
    fast_recon_dir="$current_dir/$target_domain/fastRecon__$current_date"
    mkdir -p "$fast_recon_dir" "$fast_recon_dir/gf-data" "$fast_recon_dir/subdomains" \
             "$fast_recon_dir/contents" "$fast_recon_dir/nuclei" "$fast_recon_dir/vulns"

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

    echo -e "${GREEN}${LARGE}Recon on $target_domain complete. Results saved in: $fast_recon_dir${RESET}"
done

echo -e "${GREEN}${LARGE}All reconnaissance runs complete. ($total_domains domain(s) processed)${RESET}"
