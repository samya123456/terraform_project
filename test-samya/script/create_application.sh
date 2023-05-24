#!/bin/bash
while getopts a:b:c:d:e:f:g:h:i: flag
do
  case ${flag} in
    a) ROUTEDESC=${OPTARG};;
    b) ROUTEVAL=${OPTARG};;
    c) DESCIPTION=${OPTARG};;
    d) NAME=${OPTARG};;
    e) CLIENTID=${OPTARG};;
    f) CLIENTSECRET=${OPTARG};;
    g) GRANTTYPE=${OPTARG};;
    h) NETWORKITEMID=${OPTARG};;
    i) NETWORKITEMTYPE=${OPTARG};;    
    *) echo -e "Option ${flag} not supported" && exit 1;;
  esac
done


echo "ROUTEDESC = $ROUTEDESC"
echo "ROUTEVAL = $ROUTEVAL"
echo "DESCIPTION = $DESCIPTION"
echo "NAME = $NAME"
echo "CLIENTID = $CLIENTID"
echo "CLIENTSECRET = $CLIENTSECRET"
echo "GRANTTYPE = $GRANTTYPE"
echo "NETWORKITEMID = $NETWORKITEMID"
echo "NETWORKITEMTYPE = $NETWORKITEMTYPE"

# ROUTEDESC=nandy.com
# ROUTEVAL=nandy.com
# DESCIPTION=App
# NAME=App
# CLIENTID="punGyMf71UnfT74vwVLYkIPzncNry1ZC.samyanandy"
# CLIENTSECRET="uUgvlvsydP15hiDnCnutK5UQNrVRZmCfjy5qrlIIA7onmEffTqEfIMaVwWUzppfN"
# GRANTTYPE="client_credentials"
# NETWORKITEMID="dd5eccd2-0a35-4c3f-8b68-594ce2020c8f"
# NETWORKITEMTYPE="NETWORK"
#### ./create_application.sh -a "nandy.com" -b "nandy.com" -c "App" -d "App" -e "punGyMf71UnfT74vwVLYkIPzncNry1ZC.samyanandy" -f "uUgvlvsydP15hiDnCnutK5UQNrVRZmCfjy5qrlIIA7onmEffTqEfIMaVwWUzppfN" -g "client_credentials" -h "dd5eccd2-0a35-4c3f-8b68-594ce2020c8f" -i "NETWORK" ###
get_token_url="https://samyanandy.api.openvpn.com/api/beta/oauth/token?client_id=$CLIENTID&client_secret=$CLIENTSECRET&grant_type=$GRANTTYPE"
create_application_url="https://samyanandy.api.openvpn.com/api/beta/services?networkItemId=$NETWORKITEMID&networkItemType=$NETWORKITEMTYPE"


##Edit the request json##
contents="$(jq --arg DESCIPTION $DESCIPTION '.description = $DESCIPTION' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json

contents="$(jq --arg NAME $NAME '.name = $NAME' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json

contents="$(jq --arg ROUTEDESC $ROUTEDESC '.routes[].description = $ROUTEDESC' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json

contents="$(jq --arg ROUTEVAL $ROUTEVAL '.routes[].value =$ROUTEVAL' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json






##Get the Access Token##
curl -X POST $get_token_url -H "accept: application/json"  > json/out.json
access_token=($(jq -r '.access_token'  ./json/out.json))
echo "access_token = $access_token"

##Create The application##
res=$(curl -X POST $create_application_url \
  --write-out "%{http_code}" \
  -H "accept: application/json" \
  -H "authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d "@json/createopenvpn_service_req.json" )

rm -rf ./json/out.json
echo "res = $res"