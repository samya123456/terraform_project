sudo apt-get update
sudo apt-get install -y postfix

sudo echo '${main_conf}' > /etc/postfix/main.cf

sudo touch /etc/postfix/virtual
sudo touch /etc/postfix/sasl_passwd
sudo touch /etc/postfix/tls_policy