#!/bin/bash
# author:annata
# url:https://github.com/annata/v2ray.sh
. /etc/profile

set -e

param(){
	trojan_port="443"
	vless_port="8443"
	shadowsocks_port="14523"
	socks5_port="1080"
}

pw(){
	trojan_password=$(uuidgen)
	vless_password=$(uuidgen)
	shadowsocks_password=$(uuidgen)
	socks5_password=$(uuidgen)
}

if [ `id -u` != "0" ]
then
	echo '必须是root权限'
	exit 1
fi
source /etc/os-release
case $ID in
debian|ubuntu|devuan)
    echo $ID
	;;
centos|fedora|rhel)
    echo '不支持该发行版'
    exit 1
	;;
*)
	echo '不支持该发行版'
    exit 1
    ;;
esac

apt-get update && apt-get install supervisor zip nginx curl wget -y
mkdir -p /root/.v2ray
cd /root/.v2ray
if [ ! -f "/root/.v2ray/v2ray" ]; then
  wget https://github.com/v2fly/v2ray-core/releases/download/v4.45.2/v2ray-linux-64.zip && unzip v2ray-linux-64.zip
fi
param
pw
CERT0=`/root/.v2ray/v2ctl cert --expire=240000h`
CERT1=`/root/.v2ray/v2ctl cert --expire=240000h`
echo -e '[program:ss]\ncommand=/root/.v2ray/v2ray -config=/root/.v2ray/config.json\nautostart=true\nautorestart=true' > /etc/supervisor/conf.d/ss.conf
TEXT='{"inbounds":[{"port":'${socks5_port}',"protocol":"socks","settings":{"auth":"password","accounts":[{"user":"user","pass":"'${socks5_password}'"}]}},{"port":'${trojan_port}',"protocol":"trojan","settings":{"clients":[{"password":"'${trojan_password}'"}],"fallbacks":[{"dest":80}]},"streamSettings":{"security":"tls","tlsSettings":{"alpn":["http/1.1"],"certificates":['${CERT0}'],"disableSystemRoot":true}}},{"port":'
TEXT=${TEXT}${vless_port}',"protocol":"vless","settings":{"clients":[{"id":"'${vless_password}'"}],"fallbacks":[{"dest":80}],"decryption":"none"},"streamSettings":{"security":"tls","tlsSettings":{"alpn":["http/1.1"],"certificates":['${CERT1}'],"disableSystemRoot":true}}},'
TEXT=${TEXT}'{"port":'${shadowsocks_port}',"protocol":"shadowsocks","settings":{"password":"'${shadowsocks_password}'","method":"chacha20-ietf-poly1305","network":"tcp,udp"}}],"outbounds":[{"protocol":"freedom"}]}'
echo -e $TEXT > /root/.v2ray/config.json
service supervisor stop && service supervisor start
echo 'trojan_port='${trojan_port}
echo 'trojan_password='${trojan_password}
echo 'vless_port='${vless_port}
echo 'vless_password='${vless_password}
echo 'shadowsocks_port='${shadowsocks_port}
echo 'shadowsocks_password='${shadowsocks_password}
echo 'socks5_port='${socks5_port}
echo 'socks5_password='${socks5_password}