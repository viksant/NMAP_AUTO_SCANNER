#!/bin/bash

# Colors variables
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
blue='\033[0;34m'
magenta='\033[0;35m'
cyan='\033[0;36m'
reset='\033[0m'

# Function to extract the ports from the scanner's output file:
function extractPorts(){
    ports="$(cat $1 | grep -oP '\d{1,5}/open' | awk '{print $1}' FS='/' | xargs | tr ' ' ',')"
    ip_address="$(cat $1 | grep -oP '\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}' | sort -u | head -n 1)"
    echo -e "\n[*] Extracting information...\n" > extractPorts.tmp
    echo -e "\t[*] IP Address: $ip_address"  >> extractPorts.tmp
    echo -e "\t[*] Open ports: $ports\n"  >> extractPorts.tmp
    echo $ports | tr -d '\n' | xclip -sel clip
    echo -e "[*] Ports copied to clipboard\n"  >> extractPorts.tmp
    cat extractPorts.tmp; rm extractPorts.tmp
}

# Display scan results:
function showResults(){
	if [ -f /usr/bin/batcat ]; then
		/usr/bin/batcat targeted -l java
	else 
		/usr/bin/cat targeted
	fi
}

echo -e "${magenta}[+] NMAP AUTO SCANNER${reset}"

echo -e  "${cyan}Consider running this script as SUDO${reset}"

if [ "$#" -lt 1 ]; then
  echo -e  "${red}Error: Script expects at least 1 argument(s).${reset}" >&2
  exit 1
fi

echo "1. TCP scan"
echo "2. UDP scan"
echo -e "3. Combined scan\n"

read -p "Please select an option:" choice 

# TCP SCAN
if [ $choice == 1 ]; then
	echo -e "\n${yellow}TCP SCAN MODE:\n${reset}"
	sudo nmap -p- --open -sS --min-rate 10000 $1 -n -Pn -oG AllPorts_TCP
	echo -e "\n"
	echo -e "${green}Extracting ports...${reset}" 
	extractPorts AllPorts_TCP
	ports=$(xclip -selection clipboard -o)
	
	echo -e "${yellow}[+] Applying a deeper scan...${reset}"
	sudo nmap -p$ports -sCV $1 -oN targeted
	echo -e "${green}TCP SCAN DONE${reset}"
	showResults

# UDP SCAN
elif [ $choice == 2 ]; then

	echo -e "${yellow}UDP SCAN MODE:${reset}"
	read -p "Do you want to scan the 100 top ports? y/n: " udp_choice

	if [ $udp_choice == "y" ]; then
		sudo nmap -sU --top-ports 100 --open -T5 -v -n $1 -oG AllPorts_UDP
	else
		sudo nmap -sU -p- --open -T5 -v -n $1 -oG AllPorts_UDP
	fi
	echo -e "\n"
	echo -e "${green}[+] Extracting ports...${reset}" 
	extractPorts AllPorts_UDP

	ports=$(xclip -selection clipboard -o)
	
	echo -e "${yellow}[+] Applying a deeper scan...${reset}"
	echo -e "\n"
	sudo nmap -p$ports -sCV $1 -oN targeted

	showResults

	echo -e "${green}[+] UDP SCAN DONE${reset}"

	# COMPLETE SCAN
else 
	echo -e "${yellow}[+] COMPLETE SCAN MODE:${reset}"

	sudo nmap -sS -sU -p- --open --min-rate 10000 $1 -n -Pn -oG AllPorts_Both
	echo -e "\n"
	echo -e "${green}[+] Extracting ports...${reset}" 
	extractPorts AllPorts_Both

	ports=$(xclip -selection clipboard -o)
	
	echo -e "${yellow}[+] Applying a deeper scan...${reset}"
	sudo nmap -p$ports -sCV $1 -oN targeted

	showResults

	echo -e "${green}[+] COMPLETE SCAN DONE${reset}"
fi
