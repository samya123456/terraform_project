#!/bin/bash
while getopts a:b:c:d:e:f: flag
do
  case ${flag} in

    a) CLIENTID=${OPTARG};;
    b) CLIENTSECRET=${OPTARG};;
    c) GRANTTYPE=${OPTARG};;
    d) NETWORKITEMID=${OPTARG};;
    e) NETWORKITEMTYPE=${OPTARG};;    
    f) BRANCHNAME=${OPTARG};; 
    *) echo -e "Option ${flag} not supported" && exit 1;;
  esac
done



echo "CLIENTID = $CLIENTID"
echo "CLIENTSECRET = $CLIENTSECRET"
echo "GRANTTYPE = $GRANTTYPE"
echo "NETWORKITEMID = $NETWORKITEMID"
echo "NETWORKITEMTYPE = $NETWORKITEMTYPE"
echo "BRANCHNAME = $BRANCHNAME"


app_list=()
app_list+=("api-$BRANCHNAME.rxmg.app")
app_list+=("dashboard-$BRANCHNAME.rxmg.app")
app_list+=("posts-$BRANCHNAME.flowintake.app")
app_list+=("$BRANCHNAME.vnt.trckng.com")

get_token_url="https://samyanandy.api.openvpn.com/api/beta/oauth/token?client_id=$CLIENTID&client_secret=$CLIENTSECRET&grant_type=$GRANTTYPE"



##Get the Access Token##
curl -X POST $get_token_url -H "accept: application/json"  > json/out.json
access_token=($(jq -r '.access_token'  ./json/out.json))
echo "access_token = $access_token"

for app in "${app_list[@]}"; do
    ./create_application_util.sh -a $app \
    -b $app -c $app -d $app -e $CLIENTID \
    -f $CLIENTSECRET -g $GRANTTYPE -h $NETWORKITEMID \
    -i "NETWORK" -j $access_token
done

rm -rf ./json/out.json