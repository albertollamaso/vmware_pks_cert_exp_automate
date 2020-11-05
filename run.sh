#!/bin/bash
# Purpose: Alert sysadmin/developer about the TLS/SSL cert expiry date in advance
# Author: Alberto Llamas  under GPL v3.x+
# ------------------------------------------------------------------------------


source env.sh
export CREDHUB_CLIENT=$BOSH_CLIENT CREDHUB_SECRET=$BOSH_CLIENT_SECRET
credhub api --server $BOSH_ENVIRONMENT:8844 --ca-cert $BOSH_CA_CERT
credhub login
bosh deployments --column=name > deployments.txt


# generate vars for each deployment
echo "Deployments:"
while IFS= read -r line; do
    if [[ $line == *"service-instance"* ]]; then
    echo $line
    credhub export -p /p-bosh/$line > $line_vars.yaml
    fi

    if [[ $line == *"harbor-container-registry"* ]]; then
    echo $line
    credhub export -p /p-bosh/$line > $line_vars.yaml
    fi

    if [[ $line == *"pivotal-container-service"* ]]; then
    echo $line
    credhub export -p /p-bosh/$line > $line_vars.yaml
    fi
done < deployments.txt


# generate report.txt with expiration dates
chmod +x review_yamls.sh
./review_yamls.sh > report.txt


# read expiration dates from report.txt
DATE_ACTUALLY_SECONDS=$(date +"%s")
CRITICAL=0
WARNING=0
echo "------------------------------------"
echo "Check certificate expiration dates:"
echo " "
while IFS= read -r line; do
    if [[ $line == *"notAfter="* ]]; then
        epoch_expiration_time=$(echo $line | sed 's/^notAfter=//g' | xargs -I{} date -d {} +%s)
        DATE_EXPIRE_FORMAT=$(date -I --date="@${epoch_expiration_time}")
        DATE_DIFFERENCE_SECONDS=$((${epoch_expiration_time}-${DATE_ACTUALLY_SECONDS}))
        DATE_DIFFERENCE_DAYS=$((${DATE_DIFFERENCE_SECONDS}/60/60/24))
        
        if [[ "${DATE_DIFFERENCE_DAYS}" -le "${CRITICAL_DAYS}" && "${DATE_DIFFERENCE_DAYS}" -ge "0" ]]; then
            #echo -e "CRITICAL: Cert will expire on: "${DATE_EXPIRE_FORMAT}""
            let CRITICAL=CRITICAL+1
        elif [[ "${DATE_DIFFERENCE_DAYS}" -le "${WARNING_DAYS}" && "${DATE_DIFFERENCE_DAYS}" -ge "0" ]]; then
            #echo -e "WARNING: Cert will expire on: "${DATE_EXPIRE_FORMAT}""
            let WARNING=WARNING+1
        #elif [[ "${DATE_DIFFERENCE_DAYS}" -lt "0" ]]; then
            #echo -e "CRITICAL: Cert expired on: "${DATE_EXPIRE_FORMAT}""
        #else
            #echo -e "OK: Cert will expire on: "${DATE_EXPIRE_FORMAT}""
        fi
    fi
done < report.txt

echo "There are $CRITICAL certificates that are going to expire before $CRITICAL_DAYS days"
echo "There are $CRITICAL certificates that are going to expire before $CRITICAL_DAYS days"

echo "Please see below the report: "
echo "----------------------------------"
sleep 5
cat report.txt
echo "Done"