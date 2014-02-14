#!/bin/bash
 
IPT="/sbin/iptables"
PUB_IF="eth0"
PUB_IP="5.9.143.119"
INT_IF="br0"

[ -f /opt/scripts/firewall/blocked-ips.list ] && BADIPS=$(grep -v -E "^#|^$" /opt/scripts/firewall/blocked-ips.list)
 
$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X

/sbin/modprobe ip_conntrack
/sbin/modprobe ip_conntrack_ftp
/sbin/modprobe ip_nat_ftp

# Counter

$IPT -I INPUT -d 127.0.0.1
$IPT -I OUTPUT -s 127.0.0.1
$IPT -I INPUT -d ${PUB_IP}
$IPT -I OUTPUT -s ${PUB_IP}

$IPT -A INPUT -i lo -j ACCEPT
$IPT -A OUTPUT -o lo -j ACCEPT
 
# DROP all incomming traffic

$IPT -P INPUT DROP
$IPT -P OUTPUT DROP
$IPT -P FORWARD DROP
 
# Block all bad ips listed in file /opt/scripts/firewall/blocked-ips.list

for ip in $BADIPS
do
	$IPT -A INPUT -s $ip -j DROP
done

#$IPT -A OUTPUT -p udp --dport 123 -j ACCEPT
#$IPT -A INPUT -p udp --sport 123 -j ACCEPT
 
# Sync

$IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- Drop Syn - "
$IPT -A INPUT -i ${PUB_IF} -p tcp ! --syn -m state --state NEW -j DROP
 
# Fragments

$IPT -A INPUT -i ${PUB_IF} -f -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- Fragments Packets - "
$IPT -A INPUT -i ${PUB_IF} -f -j DROP
 
# Block bad stuff

$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL FIN,URG,PSH -j DROP
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL ALL -j DROP
 
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- NULL Packets - "
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL NONE -j DROP
 
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
 
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- XMAS Packets - "
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
 
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -m limit --limit 5/m --limit-burst 7 -j LOG --log-level 4 --log-prefix "IPT -- Fin Packets Scan - "
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags FIN,ACK FIN -j DROP # FIN packet scans
 
$IPT -A INPUT -i ${PUB_IF} -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP
 
# Allow full outgoing connection but no incomming stuff

$IPT -A INPUT -i ${PUB_IF} -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -o ${PUB_IF} -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT

# Masquarade (NAT) virtual machines network

# $IPT -t nat -A POSTROUTING -s '192.168.254.0/24' -o ${PUB_IF} -j MASQUERADE

#
# Allow SSH/HTTP/HTTPS connections
#

$IPT -A INPUT -p tcp --dports 22,80,443 -j ACCEPT

# Allow OpenVPN Tunnel setup

$IPT -A INPUT -p esp -j ACCEPT
$IPT -A INPUT -p udp -m multiport --dports isakmp,1194 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
#$IPT -A INPUT -i tun0 -j ACCEPT
#$IPT -A INPUT -i vmbr0 -j ACCEPT
$IPT -A OUTPUT -p esp -j ACCEPT
$IPT -A OUTPUT -p udp -m multiport --sports isakmp,1194 -m state --state ESTABLISHED,RELATED -j ACCEPT
#$IPT -A OUTPUT -o tun0 -j ACCEPT
#$IPT -A OUTPUT -o vmbr0 -j ACCEPT

#$IPT -A FORWARD -i tun0 -j ACCEPT
#$IPT -I FORWARD -i vmbr0 -o tun0 -j ACCEPT
#$IPT -I FORWARD -i tun0 -o vmbr0 -j ACCEPT

# Allow incoming ICMP ping pong

$IPT -A INPUT -p icmp --icmp-type 8 -m state --state NEW,ESTABLISHED,RELATED -j ACCEPT
$IPT -A OUTPUT -p icmp --icmp-type 0 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow established related connections

$IPT -A FORWARD -i ${PUB_IF} -o ${INT_IF} -m state --state ESTABLISHED,RELATED -j ACCEPT
$IPT -A FORWARD -i ${INT_IF} -o ${PUB_IF} -j ACCEPT

# Drop everything else

$IPT -A INPUT -j DROP

exit 0
