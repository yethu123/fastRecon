#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
LARGE='\e[1m'
RESET='\033[0m'

# Get the current working directory and store it in a variable
current_dir=$(pwd)

# Get the current date in the desired format (YYYY-MM-DD)
current_date=$(date +'%Y-%m-%d')

# Initialize other variables
default_exclude_domain="bit.ly"
exclude_domain=""
run_aquatone=false
run_wafw00f=false
run_nuclei=false  # Flag to run nuclei
subdomainThreads=30
dirsearchThreads=30
dirsearchWordlist=/usr/share/dirb/wordlists/common.txt
run_dirsearch=false

while getopts ":d:e:a:w:s:n" opt; do
  case $opt in
    d)
      target_domain="$OPTARG"
      ;;
    e)
      exclude_domain="$OPTARG"
      ;;
    a)
      run_aquatone=true
      ;;
    w)
      run_wafw00f=true
      ;;
    s)
      run_dirsearch=true
      dirsearchWordlist="$OPTARG" # Use -s <dirsearch_wordlist_path>
      ;;
    n)
      run_nuclei=true
      ;;
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

# Check if the target domain is provided
if [ -z "$target_domain" ]; then
  echo -e "${RED}${LARGE}Usage: $0 -d <target_domain> [-e <exclude_domain>] [-a <To_Use_wafw00f>] [-w <To_Use_wafw00f>] [-s <wordlist_path_for_contents>] [-n <To_Use_nuclei>]${RESET}"
  exit 1
fi

# Use the current directory in place of /home/kali/recon/
fast_recon_dir="$current_dir/$target_domain/fastRecon_$current_date"

# Create necessary directories
mkdir -p "$fast_recon_dir"
mkdir -p "$fast_recon_dir/gf-data"
mkdir -p "$fast_recon_dir/subdomains"
mkdir -p "$fast_recon_dir/contents"
mkdir -p "$fast_recon_dir/nuclei"
mkdir -p "$fast_recon_dir/vulns"

# Function to run Aquatone
run_aquatone() {
  if [ "$run_aquatone" = true ]; then
    echo -e "${YELLOW}${LARGE}Running Aquatone...${RESET}"
    cat "$fast_recon_dir/subdomains/subdomains.txt" | aquatone -out "$fast_recon_dir/aquatone"
    echo -e "${GREEN}${LARGE}Aquatone was done.${RESET}"
  fi
}

# Function to run Wafw00f
run_wafw00f() {
  if [ "$run_wafw00f" = true ]; then
    echo -e "${YELLOW}${LARGE}Running Wafw00f...${RESET}"
    wafw00f -i "$fast_recon_dir/httpx.txt" -o "$fast_recon_dir/wafw00f.txt"
    echo -e "${GREEN}${LARGE}Wafw00f was done.${RESET}"
  fi
}

# Function to run Subfinder
run_subfinder() {
  echo -e "${YELLOW}${LARGE}Running Subfinder...${RESET}"
  subfinder -d "$target_domain" -o "$fast_recon_dir/subdomains/subfinder.txt"
  echo -e "${GREEN}${LARGE}Subfinder scanning was done.${RESET}"
}

# Function to run Assetfinder
run_assetfinder() {
  echo -e "${YELLOW}${LARGE}Running Assetfinder...${RESET}"
  assetfinder "$target_domain" > "$fast_recon_dir/subdomains/assetfinder.txt"
  echo -e "${GREEN}${LARGE}Assetfinder scanning was done.${RESET}"
  cat "$fast_recon_dir/subdomains/assetfinder.txt" "$fast_recon_dir/subdomains/subfinder.txt" | anew "$fast_recon_dir/subdomains/subdomains.txt"
  # Combine all output in one file
  cat "$fast_recon_dir/subdomains/subfinder.txt" "$fast_recon_dir/subdomains/assetfinder.txt" >> "$fast_recon_dir/subdomains/subdomains_output.txt"

  # Sorting
  sort -u "$fast_recon_dir/subdomains/subdomains_output.txt" > "$fast_recon_dir/subdomains/subdomainsSorted.txt"

  # Writing with anew
  cat "$fast_recon_dir/subdomains/subdomainsSorted.txt" | grep .$target_domain | anew "$fast_recon_dir/subdomains/subdomains.txt"
}






# Function to run HTTP enumeration with httpx
run_httpx() {
  echo -e "${YELLOW}${LARGE}Running httpx...${RESET}"
  cat "$fast_recon_dir/subdomains/subdomains.txt" | httpx -t 50 -p 80,443,8000,8080,8443  | anew "$fast_recon_dir/httpx.txt"
  echo -e "${GREEN}${LARGE}Hosts alive with httprobe.${RESET}"
}
# Function to run Wayback URLs
run_waybackurls() {
  echo -e "${YELLOW}${LARGE}Running Wayback URLs...${RESET}"
  cat "$fast_recon_dir/httpx.txt" | waybackurls | anew "$fast_recon_dir/waybackurl.txt"
  cat "$fast_recon_dir/httpx.txt" | gau | anew "$fast_recon_dir/waybackurl.txt"
  cat "$fast_recon_dir/waybackurl.txt" | grep $target_domain >>  "$fast_recon_dir/waybackurls.txt"
  echo -e "${GREEN}${LARGE}Wayback URLs were captured.${RESET}"
}

# Function to run GF (GrepFuzz)
run_grepfuzz() {
  echo -e "${YELLOW}${LARGE}Running GF (GrepFuzz)...${RESET}"
  cat "$fast_recon_dir/waybackurls.txt" | gf redirect | anew "$fast_recon_dir/gf-data/redirect.xt"
  cat "$fast_recon_dir/waybackurls.txt" | gf ssrf | anew "$fast_recon_dir/gf-data/ssrf.urls"
  cat "$fast_recon_dir/waybackurls.txt" | gf ssti | anew "$fast_recon_dir/gf-data/ssti.urls"
  cat "$fast_recon_dir/waybackurls.txt" | gf idor | anew "$fast_recon_dir/gf-data/idor.urls"
  cat "$fast_recon_dir/waybackurls.txt" | gf lfi | anew "$fast_recon_dir/gf-data/lfi.urls"
  cat "$fast_recon_dir/waybackurls.txt" | gf xss | anew "$fast_recon_dir/gf-data/xss.urls"
  cat "$fast_recon_dir/waybackurls.txt" | gf sqli| anew "$fast_recon_dir/gf-data/sqli.urls"
  echo -e "${GREEN}${LARGE}GF (GrepFuzz) was done.${RESET}"
}

# Function to run Dirsearch
run_dirsearch() {
  if [ "$run_dirsearch" = true ]; then
    echo "Starting dirsearch..."
    cat "$fast_recon_dir/httpx.txt" | xargs -P$subdomainThreads -I % sh -c "dirsearch -e php,asp,aspx,jsp,html,zip,jar -w $dirsearchWordlist -t $dirsearchThreads -r -R 3 --recursion-status 200-399 -u % -o $fast_recon_dir/contents/dirsearch.txt"
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


# Function to run Nuclei
run_nuclei() {
  if [ "$run_nuclei" = true ]; then
    echo -e "${YELLOW}${LARGE}Running Nuclei...${RESET}"
    nuclei -l "$fast_recon_dir/httpx.txt" -o "$fast_recon_dir/nuclei/nuclei.txt"
    echo -e "${GREEN}${LARGE}Nuclei scanning was done.${RESET}"
    afrog -T "$fast_recon_dir/httpx.txt" -o "$fast_recon_dir/nuclei/afrog.html"
    echo -e "${GREEN}${LARGE}Afrog scanning was done.${RESET}"
  fi
}

# Function to run Subfinder again with discovered subdomains
#run_subfinder_again() {
#  echo -e "${YELLOW}${LARGE}Running Subfinder again with discovered subdomains...${RESET}"
#  subfinder -dL "$fast_recon_dir/subdomains/subdomains.txt" -o "$fast_recon_dir/subdomains/subfinder1.txt"
#}

# Task execution
run_subfinder
run_assetfinder
run_httpx
run_waybackurls
run_grepfuzz
run_aquatone
run_wafw00f
run_dirsearch
run_nuclei  # Add Nuclei to the workflow
#run_subfinder_again
