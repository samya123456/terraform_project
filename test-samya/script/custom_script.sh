#!/bin/bash
while getopts b: flag
do
  case ${flag} in
    b) branch_name=${OPTARG};;
    *) echo -e "Option ${flag} not supported" && exit 1;;
  esac
done

echo "branch_name = $branch_name"
# echo "json_path = $json_path"
gcloud projects get-iam-policy rxmg-infrastructure --format="json" --flatten="bindings[].members[]" --filter="bindings.members:\"deleted:serviceAccount:\""  > policy.json
branch_name=rxp-1919
regex_expr=deleted:serviceAccount:$branch_name*-backend-sa
json_path=json/policy.json
members=($(jq -r  --arg regex_expr $regex_expr '.[].bindings |  select(.members? | match($regex_expr)) | .members' $json_path))
role=($(jq -r  --arg regex_expr $regex_expr '.[].bindings |  select(.members? | match($regex_expr)) | .role' $json_path))
arraylength=${#members[@]}
echo "members = $members"
echo "role = $role"
 if [ -z "$members" ]; then
      echo "No  member found for branch $branch_name"
      exit 0
 fi

 if [ -z "$role" ]; then
      echo "No  role found for branch $branch_name"
      exit 0
 fi

gcloud projects remove-iam-policy-binding rxmg-infrastructure --member="deleted:serviceAccount:rxp-1919-backend-sa@rxmg-infrastructure.iam.gserviceaccount.com?uid=108620316952051810520" --role="roles/logging.logWriter"
echo "iam-policy-binding for member $members and role $role deleted successfully"
# for (( i=0; i<${arraylength}; i++ ));
# do
#   echo "index: $i, value: ${members[$i]}"
# done
# echo "Array size: " ${#members[@]}
# echo "Array elements: "${members[@]}