#!/bin/bash

# Creates iptables/afwall blocking rules (IPv4) based on ASN information
# Version: 0.1
# Last updated: Apr 25 2017
# Author: Mike Kuketz
# Visit: www.kuketz-blog.de

##############
# Edit here  #
##############
# Define companys
# For example: company_array=(Google Facebook COMPANY)
company_array=(Google Facebook)
# Define iptables/afwall path
IPTABLES="/sbin/iptables"
AFWALL="/system/bin/iptables"

##############
# Functions  #
##############
# Convert CIDR notation (eg. 192.168.0.0/24) of a subnetmask to dotted decimal form (255.255.255.0)
cdr2mask ()
{
	# Number of args to shift, 255..255, first non-255 byte, zeroes
	set -- $(( 5 - ($1 / 8) )) 255 255 255 255 $(( (255 << (8 - ($1 % 8))) & 255 )) 0 0 0
	[ $1 -gt 1 ] && shift $1 || shift
	echo ${1-0}.${2-0}.${3-0}.${4-0}
}
# Read the file in parameter and fill the array named "array"
getArray() {
        array=() # Create array
        while IFS= read -r line # Read a line
        do
                array+=("$line") # Append line to the array
        done < "$1"
}

##################
# Prepare Files  #
##################
# Cleanup all existing files
touch iptables_asn.txt
touch afwall_asn.txt
> iptables_asn.txt
> afwall_asn.txt

################
# Do the magic #
################
# Loop through 'company_array'
for company in "${company_array[@]}"
do
	# Get all company ASNs
	echo "---[Get all $company ASNs]---"
	curl --silent "https://www.ultratools.com/tools/asnInfoResult?domainName=${company}" | grep -Eo 'AS[0-9]+' > asn.txt
	printf "## Company: ${company}\n" >> iptables_asn.txt
	printf "## Company: ${company}\n" >> afwall_asn.txt

	# Create 'asn_array'
	getArray "asn.txt"
	asn_array=("${array[@]}")   
	counter=1

	# Loop through 'asn_array' 
	for asn in "${asn_array[@]}"
	do
		# Store networks from ASN in file
		echo "---[Get $company networks for $asn]---"
		curl --silent "https://stat.ripe.net/data/announced-prefixes/data.json?preferred_version=1.1&resource=${asn}" | grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}' | uniq > nets.txt
		printf "## ${company}-ASN: ${asn}\n" >> iptables_asn.txt
		printf "## ${company}-ASN: ${asn}\n" >> afwall_asn.txt

		# Create NETWORK array
		getArray "nets.txt"
		echo "---[Creating iptables rules for $company $asn]---"

		# Loop through NETWORK array
		for net in "${array[@]}"
		do
			# Write new objects to files [customnetworks|customgroups]		
			printf "${IPTABLES} -A OUTPUT -d ${net} -j REJECT\n" >> iptables_asn.txt
			printf "${AFWALL} -A \"afwall\" -d ${net} -j REJECT\n" >> afwall_asn.txt
		done
	done
	printf "\n" >> iptables_asn.txt
	printf "\n" >> afwall_asn.txt
done

####################
# Still work to do #
####################

# Cleanup
echo "---[Doing cleanup]---"
rm asn.txt
rm nets.txt

# Ready
echo "---[All done!]---"
echo "---[Open 'iptables_asn.txt' | 'afwall_asn.txt' and copy the rules]---"
