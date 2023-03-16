curl https://www.mongodb.org/static/pgp/server-5.0.asc | sudo apt-key add -
echo "deb http://repo.mongodb.org/apt/debian buster/mongodb-org/5.0 main" | sudo tee /etc/apt/sources.list.d/mongodb-org-5.0.list

sudo apt-get update
sudo apt-get install -y mongodb-org=5.0.2 mongodb-org-database=5.0.2 mongodb-org-server=5.0.2 mongodb-org-shell=5.0.2 mongodb-org-mongos=5.0.2 mongodb-org-tools=5.0.2

echo "mongodb-org hold" | sudo dpkg --set-selections
echo "mongodb-org-database hold" | sudo dpkg --set-selections
echo "mongodb-org-server hold" | sudo dpkg --set-selections
echo "mongodb-org-shell hold" | sudo dpkg --set-selections
echo "mongodb-org-mongos hold" | sudo dpkg --set-selections
echo "mongodb-org-tools hold" | sudo dpkg --set-selections

sudo mkdir -p /mnt/disks/mongodb
sudo chmod 777 /mnt/disks/mongodb

sudo mount -o discard,defaults /dev/sdb /mnt/disks/mongodb
success=$?
if [ $success -ne 0 ]; then
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
    sudo mount -o discard,defaults /dev/sdb /mnt/disks/mongodb
    echo "The disk was formatted and mounted." >> /var/tmp/formatted
else
    echo "The disk was only mounted, not formatted." >> /var/tmp/mounted
fi

sudo mkdir -p /mnt/disks/mongodb/data
sudo chmod 777 /mnt/disks/mongodb/data

echo '${replica_set_shared_password}' > /var/tmp/mongo-keyfile

sudo chmod 400 /var/tmp/mongo-keyfile
sudo chown -R mongodb:mongodb /var/tmp/mongo-keyfile

echo '${mongod_conf}' > /etc/mongod.conf

echo never > /sys/kernel/mm/transparent_hugepage/enabled

sudo systemctl start mongod
sudo systemctl enable mongod