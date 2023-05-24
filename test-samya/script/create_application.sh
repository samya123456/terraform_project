#!/bin/bash
# while getopts b: flag
# do
#   case ${flag} in
#     b) branch_name=${OPTARG};;
#     *) echo -e "Option ${flag} not supported" && exit 1;;
#   esac
# done


#echo "branch_name = $branch_name"
client_id="punGyMf71UnfT74vwVLYkIPzncNry1ZC.samyanandy"
client_secret="uUgvlvsydP15hiDnCnutK5UQNrVRZmCfjy5qrlIIA7onmEffTqEfIMaVwWUzppfN"
grant_type="client_credentials"
networkItemId="dd5eccd2-0a35-4c3f-8b68-594ce2020c8f"
networkItemType="NETWORK"
get_token_url="https://samyanandy.api.openvpn.com/api/beta/oauth/token?client_id=$client_id&client_secret=$client_secret&grant_type=client_credentials"
echo "get_token_url = $get_token_url"

curl -X POST $get_token_url -H "accept: application/json"  > json/out.json
access_token=($(jq -r '.access_token'  ./json/out.json))
echo "access_token = $access_token"

create_application_url="https://samyanandy.api.openvpn.com/api/beta/services?networkItemId=$networkItemId&networkItemType=$networkItemType"

echo "create_application_url = $create_application_url"

res=$(curl -X POST $create_application_url \
  --write-out "%{http_code}" \
  -H "accept: application/json" \
  -H "authorization: Bearer $access_token" \
  -H "Content-Type: application/json" \
  -d "@json/createopenvpn_service_req.json" )

rm -rf ./json/out.json
echo "res = $res"