db = db.getSiblingDB("${database_name}");
db.createUser( { user: "${user}", pwd: "${password}", roles: [ "readWrite"]});