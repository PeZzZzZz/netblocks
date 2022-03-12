#!/bin/bash 
echo -e "Net/Blocks\n"

function help(){
 echo "usage: $0 [-d <domain>] | [-i <ip>] | [-g -i <ip>] | -a <asn>
 -d : Search by domain
 -i : Search by ip
 -a : Search by as number
 -g : To use with -i to geolocate the ip
 -h : This help" | sed 's/^[[:space:]]*//'
 exit 0
}

function lookup(){
  IP="$1"
  CONTENT=`curl https://bgpview.io/ip/${IP} -s -XGET`                         
  AS=`echo "$CONTENT" | grep 'bgpview.io/asn' |grep -Po '<a(?:\s[^>]*)?>\K.*?(?=</a>)' |tail -1`  
  ASDESC=`echo "$CONTENT" | grep -A 1 'bgpview.io/asn' |xargs -d '\n' |grep -Po '<td(?:\s[^>]*)?>\K.*?(?=</td>)' |tail -1`
  COMPAGNY=`echo "$CONTENT" | grep -A 2 'bgpview.io/asn' |xargs -d '\n' |grep -Po '<td(?:\s[^>]*)?>\K.*?(?=</td>)' |tail -1`
  
  echo "[+] Domain: $DOMAIN
        [+] IP: $IP
        [+] ASN: $AS                                                                            
        [+] AS Desc: $ASDESC
        [+] Compagny: $COMPAGNY" | sed 's/^[[:space:]]*//'
  
  if [[ "$ASDESC" == "CLOUDFLARENET" ]]; then
    echo "[!] Cloudflare detected, bypass it and come back with option -i"
    exit 1
  fi
  
  echo "-------------------------------------------------------------"
  echo "[+] IP Blocks"
  whois -h whois.radb.net -- "-i origin $AS" | grep 'route:' | awk '{print$2}'
}

function asn(){
  AS="$1"
  WHOIS=`curl -s "https://bgpview.io/asn/${AS}#whois" |grep -E "org-name:|address:|import:|export:"`
  ADDRESS=`echo "$WHOIS" | grep address | head -5 | tail -3 | cut -d: -f2 |sed 's/^[ \t]*//'`
  CITY=`echo "$ADDRESS" | head -1`
  COUNTRY=`echo "$ADDRESS" | head -2 | tail -1`
  ASDESC=`echo "$ADDRESS" | tail -1`
  IMPORT=`echo "$WHOIS" | grep 'import:' | cut -d: -f2 | sed 's/^[ \t]*//'`
  EXPORT=`echo "$WHOIS" | grep 'export:' | cut -d: -f2 | sed 's/^[ \t]*//'`
  echo "[+] ASN: $AS                                                                            
  [+] AS Desc: $ASDESC
  [+] City: $CITY
  [+] Country: $COUNTRY
  [+] Import: $IMPORT
  [+] Export: $EXPORT" | sed 's/^[[:space:]]*//'
  
  echo "-------------------------------------------------------------"
  echo "[+] IP Blocks"
  whois -h whois.radb.net -- "-i origin $AS" | grep 'route:' | awk '{print$2}'
}

function geoip(){
  curl -s -d "ip=$1&submit=Submit+Query" -XPOST "https://geoip.com/" | grep success -A 13 |sed -e 's/<.*>//g; /^$/d'
}

LOOKUPDOM=false
LOOKUPIP=false
GEOIP=false
while getopts ":h:d:i:a:g" option; do
   case $option in
      h) # display Help
         help
         exit;;
      d) #echo "[*] Lookup by domain"
         LOOKUPDOM=true
         DOMAIN=$OPTARG
         IP=`host ${DOMAIN} |head -1 |awk '{print$4}'`
         ;;
      i) #echo "[*] Lookup by ip"
         LOOKUPIP=true
         IP=$OPTARG
         ;;
      a) #echo "[*] Lookup by AS number"
         AS=$OPTARG
         ;;
      g) #echo "[*] Geolocation"
         GEOIP=true
         #echo "-g $IP"
         ;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
      *) help
         exit
         ;;
   esac
done
shift $(($OPTIND - 1))

if [ $OPTIND -eq 1 ]; then 
  help
fi

if $GEOIP; then
  echo "[*] Geolocation"
  if [ ! -z $IP ]; then
    LOOKUPIP=false
    geoip $IP
    exit 0
  else
    help
  fi
fi

if $LOOKUPDOM; then
  echo "[*] Lookup by domain"
  lookup $IP
  exit 0
fi

if $LOOKUPIP; then
  echo "[*] Lookup by ip"
  lookup $IP
  exit 0
fi

if [ ! -z $AS ]; then
  echo "[*] Lookup by AS number"
  asn $AS
  exit 0
fi


