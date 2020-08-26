#!/bin/bash
# Export GIT_PROXY_COMMAND TO THIS
# usable with settings:
# no_proxy="$no_proxy,ti.com"
# http_proxy="http://wwwgate.ti.com:80/"
# OR
# http_proxy="http://wwwgate.ti.com:80"
# OR
# http_proxy=http://proxyconfig.itg.ti.com/proxy.pac

# Apps required
WGET=/usr/bin/wget
CORKSCREW=/usr/bin/corkscrew
SOCKET=/usr/bin/socket
# Special note on pacparse
# http://code.google.com/p/pacparser/
# I hand statically built this for ubuntu 9.10
# but you can clone and install this original install
# will be pactester - just rename the following to use
PACPARSE=pacparse

use_proxy=1

# Set this up if you are going to use this seamlessly
# over vpn
use_at_home=0

if [ $use_at_home -eq 1 ]; then
	k=`ifconfig|grep tun0`
	if [ -n "$k" ]; then
		use_proxy=1
	else
		use_proxy=0
	fi
fi

while [ -n "$no_proxy" ]; do
	no_proxy_entry=${no_proxy%%,*}
	if [ "$1" != "${1%$no_proxy_entry}" ]; then
		#echo "no_proxy match:  $1 is in $no_proxy_entry"
		use_proxy=0
		break;
	fi
	if [ "$no_proxy_entry" = "$no_proxy" ]; then
		break
	fi
	no_proxy=${no_proxy#*,}
done

if [ $use_proxy = 0 ]; then
	(cat | $SOCKET $1 $2)
else
	if [ -z "$GIT_PROXY_HOST" -o -z "$GIT_PROXY_PORT" ]; then
		if [ -z "$http_proxy" ]; then
			echo "FAILED ($1 $2)!! no proxy options? yet need proxy?" 1>&2
		fi
		pac=`echo "$http_proxy"|grep "pac$"`
		if [ -n "$pac" ]; then
			#parse pac file
			LOC="http://$1"
			$WGET -O /tmp/proxy.pac "$http_proxy"
			http_proxy=`$PACPARSE -p /tmp/proxy.pac -u $LOC|cut -d ' ' -f2`
		else
			http_proxy=`echo $http_proxy|tr -d '/'|sed -e "s/http://g"`
		fi
		#parse normal http_proxy config
		export GIT_PROXY_HOST=`echo "$http_proxy"|cut -d ':' -f1`
		export GIT_PROXY_PORT=`echo "$http_proxy"|cut -d ':' -f2`
	fi
	exec $CORKSCREW $GIT_PROXY_HOST $GIT_PROXY_PORT $*
fi


