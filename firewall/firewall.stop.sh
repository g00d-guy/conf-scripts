#!/bin/bash

IPT="/sbin/iptables"
PUB_IF="eth0"

$IPT -t nat -D POSTROUTING -s '192.168.254.0/24' -o ${PUB_IF} -j MASQUERADE

$IPT -F
$IPT -X
$IPT -t nat -F
$IPT -t nat -X
$IPT -t mangle -F
$IPT -t mangle -X
$IPT -P INPUT ACCEPT
$IPT -P OUTPUT ACCEPT
$IPT -P FORWARD ACCEPT

exit 0
