CREATE DATABASE ${database_name};
CREATE DATABASE ${datastore_database_name};
GRANT ALL PRIVILEGES ON ${database_name}.* TO 'rxplatform'@'%';
GRANT ALL PRIVILEGES ON ${datastore_database_name}.* TO 'rxplatform'@'%';
FLUSH PRIVILEGES;