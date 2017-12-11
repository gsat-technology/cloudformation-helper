#!/bin/bash

config_yml=

if [ -z ${1+x} ]
then
 echo "usage: ./cfh_update.sh <path_to_cfg_config.yml>"
 exit 1
else 
  config_yml=$1
fi

#function from https://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

find . -iname $config_yml -type f -exec sed -i '' 's/[[:space:]]\{1,\}$//' {} \+

yaml=$(parse_yaml $config_yml)
echo "starting cloudformation helper"

stackname=
template=
params=

for item in $yaml
do
  
  echo $item | grep "stack_name" > /dev/null
  if [ $? -eq 0 ]
  then
    pair=(${item//=/ })
    stackname=$(echo ${pair[1]} | tr -d '"')
    continue
  fi

  echo $item | grep "stack_template" > /dev/null
  if [ $? -eq 0 ]
  then
    pair=(${item//=/ })
    template=$(echo ${pair[1]} | tr -d '"')
    continue
  fi

  echo $item | grep "stack_parameters" > /dev/null
  if [ $? -eq 0 ]
  then
    clean=${item#stack_parameters_}
    pair=(${clean//=/ })
    params="$params ParameterKey=${pair[0]},ParameterValue=${pair[1]} "
    continue
  fi
done


uuid=$(uuidgen)
tmp=a${uuid:0:6}
changeSetName=`echo $tmp | awk '{print tolower($0)}'`

id=$(aws cloudformation create-change-set \
    --change-set-name $changeSetName \
    --stack-name $stackname \
    --template-body file://$template \
    --capabilities CAPABILITY_IAM \
    --parameters \
                 $params \
    --query 'Id' \
    --output text
    )

changeSetResult=$(aws cloudformation describe-change-set \
   --change-set-name $changeSetName \
   --stack-name $stackname)

status=$(echo $changeSetResult | jq '.Status' -r)

if [ $status == "FAILED" ]
then
  reason=$(echo $changeSetResult | jq '.StatusReason' -r)
  echo "changeset creation failed"
  echo "reason: $reason"
  exit 4
elif [ $status == "CREATE_IN_PROGRESS" ]
then 
  changeSetId=$(echo $changeSetResult | jq '.ChangeSetId' -r)
  printf "waiting for changeset to be created"

  while true
  do
    changeSetResult=$(aws cloudformation describe-change-set \
      --change-set-name $changeSetId)
    status=$(echo $changeSetResult | jq '.Status' -r)

    if [ $status == "CREATE_COMPLETE" ]
    then
      break
    else 
      printf "."
    fi
  done

  echo ""
  echo "changeset successfully created"
  echo "changes:"
  echo $changeSetResult | jq '.Changes'
  echo "update stack (y/n)"
  read input_variable

  if [ "$input_variable" == "y" ]; then
    aws cloudformation execute-change-set \
       --change-set-name $changeSetName \
       --stack-name $stackname
  else
    echo "not updating stack"
  fi
else 
  echo ""
fi

