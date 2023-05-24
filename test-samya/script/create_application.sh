#!/bin/bash
# while getopts b: flag
# do
#   case ${flag} in
#     b) branch_name=${OPTARG};;
#     *) echo -e "Option ${flag} not supported" && exit 1;;
#   esac
# done

appName=App
routesdesc=nandy.com
routeval=nandy.com
description=App
name=App
client_id="punGyMf71UnfT74vwVLYkIPzncNry1ZC.samyanandy"
client_secret="uUgvlvsydP15hiDnCnutK5UQNrVRZmCfjy5qrlIIA7onmEffTqEfIMaVwWUzppfN"
grant_type="client_credentials"
networkItemId="dd5eccd2-0a35-4c3f-8b68-594ce2020c8f"
networkItemType="NETWORK"
get_token_url="https://samyanandy.api.openvpn.com/api/beta/oauth/token?client_id=$client_id&client_secret=$client_secret&grant_type=client_credentials"
create_application_url="https://samyanandy.api.openvpn.com/api/beta/services?networkItemId=$networkItemId&networkItemType=$networkItemType"


##Edit the request json##
contents="$(jq --arg description $description '.description = $description' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json

contents="$(jq --arg name $name '.name = $name' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json

contents="$(jq --arg routesdesc $routesdesc '.routes[].description = $routesdesc' json/createopenvpn_service_req.json)"
echo -E "${contents}" > json/createopenvpn_service_req.json

contents="$(jq --arg routeval $routeval '.routes[].value =$routeval' json/createopenvpn_service_req.json)"
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