#!/usr/bin/env bash

install() {
echo "Enter server url:"
read url

ip=$(hostname -I|cut -f1 -d ' ')
echo "Your Server IP address is:$ip"
echo -e "\e[32mInstalling gnutls-bin\e[39m"

apt install -y gnutls-bin certbot ocserv

certbot certonly --standalone --preferred-challenges http --agree-tos --email mehdi.mamhoui.s@gmail.com -d $url

echo -e "\e[32mInstalling ocserv\e[39m"

sed -i -e 's@auth = "@#auth = "@g' /etc/ocserv/ocserv.conf
sed -i -e 's@auth = "pam@auth = "#auth = "pam"@g' /etc/ocserv/ocserv.conf
sed -i -e 's@try-mtu-discovery = false @try-mtu-discovery = true@g' /etc/ocserv/ocserv.conf
sed -i -e 's@udp-port = @#udp-port = @g' /etc/ocserv/ocserv.conf
sed -i -e "s@/etc/ssl/certs/ssl-cert-snakeoil.pem@/etc/letsencrypt/live/$url/fullchain.pem@g" /etc/ocserv/ocserv.conf
sed -i -e "s@/etc/ssl/private/ssl-cert-snakeoil.key@/etc/letsencrypt/live/$url/privkey.pem@g" /etc/ocserv/ocserv.conf
sed -i -e "s@default-domain = example.com@default-domain = $url@g" /etc/ocserv/ocserv.conf
sed -i -e 's@ipv4-network = 192.168.1.0@ipv4-network = 192.168.5.0@g' /etc/ocserv/ocserv.conf
sed -i -e 's@route =@#route =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@no-route =@#no-route =@g' /etc/ocserv/ocserv.conf
sed -i -e 's@##auth = "#auth = "pam""@auth = "plain[passwd=/etc/ocserv/ocpasswd]"@g' /etc/ocserv/ocserv.conf


echo "Enter a username:"
read username

ocpasswd -c /etc/ocserv/ocpasswd $username
iptables -t nat -A POSTROUTING -j MASQUERADE
echo "#!/bin/sh

iptables -t nat -A POSTROUTING -j MASQUERADE" >> /etc/network/if-pre-up.d/iptables-load
chmod +x /etc/network/if-pre-up.d/iptables-load
sed -i -e 's@#net.ipv4.ip_forward=@net.ipv4.ip_forward=@g' /etc/sysctl.conf
echo "net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.ipv4.tcp_window_scaling = 1" >> /etc/sysctl.conf

sysctl -p /etc/sysctl.conf

echo -e "\e[32mStopping ocserv service\e[39m"
service ocserv stop
echo -e "\e[32mStarting ocserv service\e[39m"
service ocserv start

echo "OpenConnect Server Configured Succesfully"

}

uninstall() {
  sudo apt-get purge ocserv
}

addUser() {

echo "Enter a username:"
read username

ocpasswd -c /etc/ocserv/ocpasswd $username

}

showUsers() {
cat /etc/ocserv/ocpasswd
}

deleteUser() {
echo "Enter a username:"
read username
ocpasswd -c /etc/ocserv/ocpasswd -d $username
}

lockUser() {
echo "Enter a username:"
read username
ocpasswd -c /etc/ocserv/ocpasswd -l $username
}

unlockUser() {
echo "Enter a username:"
read username
ocpasswd -c /etc/ocserv/ocpasswd -u $username
}

addUserFromFile() {
filename="/home/$SUDO_USER/users.txt"
n=1
while read line; do
# reading each line
user="$(echo $line | awk '{ print $1}')"
pass="$(echo $line | awk '{ print $2}')"
echo "$n- add user $user"
echo "$pass" | ocpasswd -c /etc/ocserv/ocpasswd $user
((n++))
done < $filename
}

if [[ "$EUID" -ne 0 ]]; then
	echo "Please run as root"
	exit 1
fi

cd ~
echo '
 ▒█████   ██▓███  ▓█████  ███▄    █     ▄████▄   ▒█████   ███▄    █  ███▄    █ ▓█████  ▄████▄  ▄▄▄█████▓
▒██▒  ██▒▓██░  ██▒▓█   ▀  ██ ▀█   █    ▒██▀ ▀█  ▒██▒  ██▒ ██ ▀█   █  ██ ▀█   █ ▓█   ▀ ▒██▀ ▀█  ▓  ██▒ ▓▒
▒██░  ██▒▓██░ ██▓▒▒███   ▓██  ▀█ ██▒   ▒▓█    ▄ ▒██░  ██▒▓██  ▀█ ██▒▓██  ▀█ ██▒▒███   ▒▓█    ▄ ▒ ▓██░ ▒░
▒██   ██░▒██▄█▓▒ ▒▒▓█  ▄ ▓██▒  ▐▌██▒   ▒▓▓▄ ▄██▒▒██   ██░▓██▒  ▐▌██▒▓██▒  ▐▌██▒▒▓█  ▄ ▒▓▓▄ ▄██▒░ ▓██▓ ░ 
░ ████▓▒░▒██▒ ░  ░░▒████▒▒██░   ▓██░   ▒ ▓███▀ ░░ ████▓▒░▒██░   ▓██░▒██░   ▓██░░▒████▒▒ ▓███▀ ░  ▒██▒ ░ 
░ ▒░▒░▒░ ▒▓▒░ ░  ░░░ ▒
░ ░░ ▒░   ▒ ▒    ░ ░▒ ▒  ░░ ▒░▒░▒░ ░ ▒░   ▒ ▒ ░ ▒░   ▒ ▒ ░░ ▒░ ░░ ░▒ ▒  ░  ▒ ░░   
  ░ ▒ ▒░ ░▒ ░      ░ ░  ░░ ░░   ░ ▒░     ░  ▒     ░ ▒ ▒░ ░ ░░   ░ ▒░░ ░░   ░ ▒░ ░ ░  ░  ░  ▒       ░    
░ ░ ░ ▒  ░░          ░      ░   ░ ░    ░        ░ ░ ░ ▒     ░   ░ ░    ░   ░ ░    ░   ░          ░      
    ░ ░              ░  ░         ░    ░ ░          ░ ░           ░          ░    ░  ░░ ░               
                                       ░                                              ░                 
 ██▒   █▓ ██▓███   ███▄    █      ██████ ▓█████  ██▀███   ██▒   █▓▓█████  ██▀███                        
▓██░   █▒▓██░  ██▒ ██ ▀█   █    ▒██    ▒ ▓█   ▀ ▓██ ▒ ██▒▓██░   █▒▓█   ▀ ▓██ ▒ ██▒                      
 ▓██  █▒░▓██░ ██▓▒▓██  ▀█ ██▒   ░ ▓██▄   ▒███   ▓██ ░▄█ ▒ ▓██  █▒░▒███   ▓██ ░▄█ ▒                      
  ▒██ █░░▒██▄█▓▒ ▒▓██▒  ▐▌██▒     ▒   ██▒▒▓█  ▄ ▒██▀▀█▄    ▒██ █░░▒▓█  ▄ ▒██▀▀█▄                        
   ▒▀█░  ▒██▒ ░  ░▒██░   ▓██░   ▒██████▒▒░▒████▒░██▓ ▒██▒   ▒▀█░  ░▒████▒░██▓ ▒██▒                      
   ░ ▐░  ▒▓▒░ ░  ░░ ▒░   ▒ ▒    ▒ ▒▓▒ ▒ ░░░ ▒░ ░░ ▒▓ ░▒▓░   ░ ▐░  ░░ ▒░ ░░ ▒▓ ░▒▓░                      
   ░ ░░  ░▒ ░     ░ ░░   ░ ▒░   ░ ░▒  ░ ░ ░ ░  ░  ░▒ ░ ▒░   ░ ░░   ░ ░  ░  ░▒ ░ ▒░                      
     ░░  ░░          ░   ░ ░    ░  ░  ░     ░     ░░   ░      ░░     ░     ░░   ░                       
      ░                    ░          ░     ░  ░   ░           ░     ░  ░   ░                           
     ░                                                        ░                                         
'


PS3='Please enter your choice: '
options=("Install" "Uninstall" "Add User" "Change Password" "Show Users" "Delete User" "Lock User" "Unlock User" "Quit" "Add User From File")
select opt in "${options[@]}"
do
    case $opt in
        "Install")
            install
			break
            ;;
        "Uninstall")
            uninstall
			break
            ;;
        "Add User")
            addUser
			break
            ;;
        "Change Password")
            addUser
			break
            ;;
        "Show Users")
	    showUsers
			break
	    ;;
        "Delete User")
	    deleteUser
			break
	    ;;
        "Lock User")
	    lockUser
			break
	    ;;
        "Unlock User")
	    unlockUser
			break
	    ;;
        "Add User From File")
      addUserFromFile
      break
      ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

