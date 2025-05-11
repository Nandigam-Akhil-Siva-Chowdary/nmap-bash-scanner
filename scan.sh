#!/bin/bash

# Welcome message
echo "============================================"
echo "  Automated Network Reconnaissance Tool"
echo "  Using Nmap and Bash"
echo "============================================"
echo ""

# Check if nmap is installed
if ! command -v nmap &> /dev/null; then
    echo "Error: Nmap is not installed. Please install it first."
    echo "On Debian/Ubuntu: sudo apt install nmap"
    echo "On RHEL/CentOS: sudo yum install nmap"
    exit 1
fi

# Get target input
read -p "Enter the target IP, IP range, or domain: " target

# Validate input
if [[ -z "$target" ]]; then
    echo "Error: No target specified."
    exit 1
fi

# Create results directory if it doesn't exist
mkdir -p results

# Generate filename with timestamp
timestamp=$(date +"%Y%m%d_%H%M%S")
filename="results/${target//[^a-zA-Z0-9]/_}_scan_$timestamp.txt"

echo ""
echo "Starting scan on: $target"
echo "Results will be saved to: $filename"
echo ""

# Function to run scan with progress indicator
run_scan() {
    local scan_type=$1
    local nmap_command=$2
    
    echo -e "\n[+] Running $scan_type..."
    
    # Start progress indicator in background
    (
        while true; do
            echo -n "."
            sleep 1
        done
    ) &
    progress_pid=$!
    
    # Run the actual scan
    echo "$scan_type Results:" >> "$filename"
    eval "$nmap_command" >> "$filename" 2>&1
    echo -e "\n" >> "$filename"
    
    # Stop progress indicator
    kill $progress_pid >/dev/null 2>&1
    wait $progress_pid 2>/dev/null
    
    echo -e "\n[+] $scan_type completed."
}

# 1. Ping Scan (Host Discovery)
run_scan "Ping Scan" "nmap -sn $target"

# 2. Quick Port Scan (Top 1000 ports)
run_scan "Quick Port Scan" "nmap -T4 $target"

# 3. Comprehensive Port Scan (All ports)
run_scan "Comprehensive Port Scan" "nmap -p- -T4 $target"

# 4. Service Version Detection
run_scan "Service Version Detection" "nmap -sV $target"

# 5. OS Detection
run_scan "OS Detection" "nmap -O $target"

# 6. Vulnerability Scan (NSE scripts)
run_scan "Vulnerability Scan" "nmap --script vuln $target"

# 7. Full Comprehensive Scan
run_scan "Full Comprehensive Scan" "nmap -A -T4 $target"

# Completion message
echo ""
echo "============================================"
echo "  Scan completed successfully!"
echo "  Full results saved to: $filename"
echo "============================================"

# Optional: Generate HTML report
read -p "Would you like to generate an HTML report? (y/n): " generate_html
if [[ "$generate_html" =~ ^[Yy]$ ]]; then
    html_filename="${filename%.*}.html"
    nmap -A -T4 $target -oX "${filename%.*}.xml" >/dev/null 2>&1
    xsltproc "${filename%.*}.xml" -o "$html_filename" >/dev/null 2>&1
    echo "HTML report generated: $html_filename"
    rm "${filename%.*}.xml"
fi
