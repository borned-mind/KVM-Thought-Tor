#!/bin/bash
function GET_BASH_COLOR {
              eval "$1='\033[$2;$3m'";
           }
GET_BASH_COLOR RED 0 31
GET_BASH_COLOR GREEN 0 32
GET_BASH_COLOR BROWN 0 33



function AddToFile {
	echo -e "${BROWN}putting to file ${1} file${NOCOLOUR}"
	echo $2 | sudo tee -a $1
}

function AddToFileIfNotExists {
	awk '!/^ *#/ && NF' $1 | grep $2 || AddToFile $1 "${3}";
	echo -e "${BROWN}Added to file if not exists${NOCOLOUR}"
}

read -e -p "Name of Interface: " -i "tornet" INTERFACE
read -e -p "Name of Tap Interface: " -i "tap0" TAPINTERFACE
read -e -p "Port of Tor TransProxy: " -i "9040" TRANSPROXPORT
read -e -p "DNS Tor port: " -i "5353" DNSPORT
read -e -p "Addr: " -i "10.100.100.0/24" ADDR

function RUN_BRIDGE {
	    sudo brctl addbr $INTERFACE
	    sudo ip link set dev $INTERFACE up
	    sudo ip addr add 10.100.100.1/24 dev $INTERFACE
	    sudo ip tuntap add dev $TAPINTERFACE mode tap
	    sudo ip link set $TAPINTERFACE master $INTERFACE
	    sudo ip link set $TAPINTERFACE up promisc on
}

function ERROR {
	echo -e "${RED}${1}${NOCOLOUR}"
	exit 1
}


NOCOLOUR="\033[0m"
if ! whereis tor > /dev/null; then
	read -e -p "I can't find Tor; I will isntall it?" "Y" InstallingTor
	if ! [ InstallingTor = "Y" ]; then
		echo -e "${RED}Is need for working!${NOCOLOUR}"
		exit 1
	fi
	sudo apt-get install tor tor-arm
fi

if ! whereis kvm > /dev/null; then
	read -e -p "I can't find KVM on your PC; I will install KVM?" "Y" InstallingKVM
	if ! [ InstallingKVM = "Y" ]; then
		echo -e "${RED}Is need for working!${NOCOLOUR}"
		exit 1
	fi
	sudo apt-get install kvm libvirt-bin virtinst virt-clone virt-manager virt-viewer
fi

read -e -p "Your Tor config? " -i "/etc/tor/torrc" TorConfig

AddToFileIfNotExists $TorConfig DNSPort "DNSPort $DNSPORT"
AddToFileIfNotExists $TorConfig TransPort "TransPort $TRANSPROXPORT"
AddToFileIfNotExists $TorConfig VirtualAddrNetwork "VirtualAddrNetwork 172.30.0.0/16"
AddToFileIfNotExists $TorConfig AutomapHostsOnResolve "AutomapHostsOnResolve 1"

echo "${BROWN}Set qemu daemon hooks{NOCOLOUR}"
AddToFile /etc/libvirt/hooks/daemon "pidfile=qemu_setup.pid
if [ ! -f "/tmp/$pidfile" ]; then
	    brctl addbr ${INTERFACE}
	    ip link set dev ${INTERFACE} up
	    ip addr add 10.100.100.1/24 dev ${INTERFACE}
	    ip tuntap add dev ${TAPINTERFACE} mode tap
	    ip link set ${TAPINTERFACE} master $INTERFACE
	    ip link set ${TAPINTERFACE} up promisc on
	    echo \$\$ > \$pidfile
fi

"  || ERROR "Can't add to daemon hooks"


echo -e "${BROWN} Add guy to group${NOCOLOUR}"
sudo usermod -aG libvirt $(whoami)

RUN_BRIDGE

sudo sysctl -w net.ipv4.conf.all.forwarding=1
sudo iptables -P FORWARD DROP
sudo iptables -A INPUT -m state --state INVALID -j DROP
sudo iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i $INTERFACE -o eno1 -p tcp -j ACCEPT
sudo iptables -A FORWARD -i $INTERFACE -o eno1 -p udp --dport=53 -j ACCEPT
sudo iptables -t nat -A POSTROUTING -s $ADDR -o eno1 -j MASQUERADE
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p udp -m udp --dport 53 -j DNAT --to-destination 127.0.0.1:$DNSPORT
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -j DNAT --to-destination 127.0.0.1:$TRANSPROXPORT
sudo iptables -A INPUT -i $INTERFACE -p tcp --dport $TRANSPROXPORT -j ACCEPT
sudo iptables -A INPUT -i $INTERFACE -p udp --dport $DNSPORT -j ACCEPT
###
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -m tcp --dport 9050 -j DNAT --to-destination 127.0.0.1:9050
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -m tcp --dport 4444 -j DNAT --to-destination 127.0.0.1:4444
sudo iptables -t nat -A PREROUTING -i $INTERFACE -p tcp -m tcp --dport 4447 -j DNAT --to-destination 127.0.0.1:4447
sudo iptables-save > /etc/iptables.rules

echo -e "${GREEN} Okey, now you will start your VM and set automatically adress. if it 10.100.100.0/24 set 10.100.100.121 as example and it will work ${NOCOLOUR}"


