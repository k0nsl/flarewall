#!/bin/bash
echo -e "\n\nFlarewall v1.0.1 Installation"
echo -e "Visit Flarewall.net [defunct] !"
echo -e "------------------------------------"
folder="/etc/csflare"
cf_block=$folder"/cs_block.txt"
cloud_url="http://www.cloudflare.com/api_json.html"


mkdir $folder >/dev/null 2>&1
cd $folder >/dev/null 2>&1

results=$(grep -i "^TCP_OUT" /etc/csf/csf.conf)
ports=$(echo $results | grep -o -P '(?<=").*(?=")')

IFS=', ' read -a array <<< "$ports"
if [[ ${array[*]} =~ '443' ]]; then
	cloud_url="https://www.cloudflare.com/api_json.html"
fi

echo -e "Please enter Cloudflare token: "
read input_cloudftoken
echo -e "Please enter Cloudflare email: "
read input_cloudfemail
echo -e "Please wait...\n"

cat > $folder/ban.sh << EOF
#!/bin/bash
TOKEN="$input_cloudftoken"
EMAIL="$input_cloudfemail"
folder="/etc/csflare"
cf_block=\$folder"/cs_block.txt"

curl -A "Flarewall Script/1.0" -d "a=ban&tkn=\$TOKEN&email=\$EMAIL&key=\$1" $cloud_url
echo \$1 >> \$cf_block
EOF

cat > $folder/nul.sh << EOF
#!/bin/bash
TOKEN="$input_cloudftoken"
EMAIL="$input_cloudfemail"
folder="/etc/csflare"
cf_block=\$folder"/cs_block.txt"

curl -A "Flarewall Script/1.0" -d "a=nul&tkn=\$TOKEN&email=\$EMAIL&key=\$1" $cloud_url
sed -i 's/\$1//g' \$cf_block
sed -i '/^$/d' \$cf_block
EOF

chmod a+x $folder/ban.sh >/dev/null 2>&1
chmod a+x $folder/nul.sh >/dev/null 2>&1

cat > /etc/cron.hourly/flarewall.sh << EOF
#!/bin/bash
folder="/etc/csflare"
allow=\$folder"/alow.txt"
cf_allow=\$folder"/cs_allow.txt"
block=\$folder"/block.txt"
cf_block=\$folder"/cs_block.txt"
cloud_url="$cloud_url"
TOKEN="$input_cloudftoken"
EMAIL="$input_cloudfemail"

function valid_ip(){
    local  ip=\$1
    local  stat=1

    if [[ \$ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=\$IFS
        IFS='.'
        ip=(\$ip)
        IFS=\$OIFS
        [[ \${ip[0]} -le 255 && \${ip[1]} -le 255 && \${ip[2]} -le 255 && \${ip[3]} -le 255 ]]
        stat=\$?
    fi
    return \$stat
}

function valid_ip_range(){
    local  ip=\$1
    local  stat=1

    if [[ \$ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\/[0-9]{1,3}$ ]]; then
        OIFS=\$IFS
        IFS='.'
        ip=(\$ip)
        IFS=\$OIFS
        [[ \${ip[0]} -le 255 && \${ip[1]} -le 255 && \${ip[2]} -le 255 && \${ip[2]} -le 255 && \${ip[4]} -le 32 ]]
        stat=\$?
    fi
    return \$stat
}

# allow
touch \$allow
> \$allow

nfiles=( "csf.allow" "csf.ignore" )

for i in "\${nfiles[@]}"
do
	while read line
	do
		name=\$line
		ip=\$(echo \${name%%#*} | tr -d '')
		# remove port
		ip=\$(echo \${ip%%:*} | tr -d '')
		if valid_ip \$ip; then
			echo \$ip >> \$allow'.tmp'
		fi
	done < '/etc/csf/'\$i
done

while read line
do
	name=\$line
	IFS='|' read -a array <<< "\$name"
	ip=\${array[1]} 
	# remove port
	ip=\$(echo \${ip%%:*} | tr -d '')
	if valid_ip \$ip; then
		echo \$ip >> \$allow'.tmp'
	fi
done < '/var/lib/csf/csf.tempallow'

sort -u \$allow'.tmp' > \$allow
rm -rf \$allow'.tmp' >/dev/null 2>&1

if [ ! -f "\$cf_allow" ]; then
	touch \$cf_allow
	> \$cf_allow
fi

while read line
do
	ip=\$line
	if ! grep \$ip "\$cf_allow" >/dev/null 2>&1
	then
		curl -A "Flarewall Script/1.0" -d "a=wl&tkn=\$TOKEN&email=\$EMAILkey="\$ip $cloud_url		
		echo \$ip >> \$cf_allow	
	fi
done < \$allow

while read line
do
	ip=\$line
	if ! grep \$ip "\$allow" >/dev/null 2>&1
	then
		curl -A "Flarewall Script/1.0" -d "a=nul&tkn=\$TOKEN&email=\$EMAIL&key="\$ip $cloud_url		
	fi
done < \$cf_allow

sort -u \$allow > \$cf_allow
rm -rf \$allow >/dev/null 2>&1


# block
touch \$block
> \$block

nfiles=( "csf.deny" )

for i in "\${nfiles[@]}"
do
	while read line
	do
		name=\$line
		ip=\$(echo \${name%%#*} | tr -d '')
		# remove port
		ip=\$(echo \${ip%%:*} | tr -d '')
		if valid_ip \$ip; then
			echo \$ip >> \$block'.tmp'
		fi
	done < '/etc/csf/'\$i
done

while read line
do
	name=\$line
	IFS='|' read -a array <<< "\$name"
	ip=\${array[1]} 
	# remove port
	ip=\$(echo \${ip%%:*} | tr -d '')
	if valid_ip \$ip; then
		echo \$ip >> \$block'.tmp'
	fi
done < '/var/lib/csf/csf.tempban'

sort -u \$block'.tmp' > \$block
rm -rf \$block'.tmp' >/dev/null 2>&1

if [ ! -f "\$cf_block" ]; then
	touch \$cf_block
	> \$cf_block
fi

while read line
do
	ip=\$line
	if ! grep \$ip "\$cf_block" >/dev/null 2>&1
	then
		curl -A "Flarewall Script/1.0" -d "a=ban&tkn=\$TOKEN&email=\$EMAIL&key="\$ip $cloud_url		
		echo \$ip >> \$cf_block	
	fi
done < \$block

while read line
do
	ip=\$line
	if ! grep \$ip "\$block" >/dev/null 2>&1
	then
		curl -A "Flarewall Script/1.0" -d "a=nul&tkn=\$TOKEN&email=\$EMAIL&key="\$ip $cloud_url		
	fi
done < \$cf_block

sort -u \$block > \$cf_block
rm -rf \$block >/dev/null 2>&1
EOF

chmod 0750 /etc/cron.hourly/flarewall.sh

# firewall 
sed -i 's/^BLOCK_REPORT.*/BLOCK_REPORT = "\/etc\/csflare\/ban.sh"/g' /etc/csf/csf.conf
sed -i 's/^UNBLOCK_REPORT.*/UNBLOCK_REPORT = "\/etc\/csflare\/nul.sh"/g' /etc/csf/csf.conf

sudo csf -x >/dev/null 2>&1
sudo csf -e >/dev/null 2>&1

echo -e "Done!\n"
