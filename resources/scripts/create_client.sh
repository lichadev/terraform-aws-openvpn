if [ $(whoami) = "ubuntu" ] && [ -n "$1" ] ; then
  mkdir -p ./keys
	docker compose run --rm openvpn easyrsa build-client-full $1 nopass
	docker compose run --rm openvpn ovpn_getclient $1 > ./keys/$1.ovpn
	printf "Client $1 created.\n You can find the configuration file in the keys folder: ./keys/$1.ovpn\n You can use this file to connect to the VPN server.\n"
elif [ $(whoami) != "ubuntu" ]; then
	echo "This script must be run as ubuntu."
	exit 1
elif [ -z "$1" ]; then
	echo "Please pass a username as first parameter."
fi
