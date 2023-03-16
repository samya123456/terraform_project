sudo apt-get update
sudo apt-get install -y haproxy

sudo echo '${haproxy_conf}' > /etc/haproxy/haproxy.cfg