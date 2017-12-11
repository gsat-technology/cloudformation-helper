#!/bin/bash

if [ -z ${1+x} ]
then
 echo "please supply stack name as first parameter."
 exit 1
fi

if [ -z ${2+x} ]
then
 echo "exiting. please supply relative path to cloudformation template as second parameter"
 exit 2
fi

which jq > /dev/null
if [ $? -ne 0 ]
then
  echo "jq not installed. please install (https://stedolan.github.io/jq/download)"
  exit 3
fi


echo "starting cloudformation helper"

stackName=$1
template=$2

paramsFile=./params.sh
params=

while read -r line
do
    if [[ $line != \#* ]]
    then 
      pair=(${line//=/ })
      params="$params ParameterKey=${pair[0]},ParameterValue=${pair[1]} "
    fi
done < "$paramsFile"


#random string for change set name
uuid=$(uuidgen)
tmp=a${uuid:0:6}
rand=`echo $tmp | awk '{print tolower($0)}'`

id=$(aws cloudformation create-change-set \
    --change-set-name $rand \
    --stack-name $stackName \
    --template-body file://$template \
    --capabilities CAPABILITY_IAM \
    --parameters \
                 $params \
    --query 'Id' \
    --output text
    )

changeSetResult=$(aws cloudformation describe-change-set \
   --change-set-name $rand \
   --stack-name $stackName)

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
       --change-set-name $rand \
       --stack-name $stackName
  else
    echo "not updating stack"
  fi
else 
  echo ""
fi

