#!/bin/bash

YAMLFILES=(`ls *yaml`)

echo "The YAML files are:"
for y in `ls *yaml`
do
  echo $y
done


echo ""
echo "Processing the YAML files now..."
echo "===================================================================="
for y in `ls *yaml`
do
  echo "     Processing $y..."
  echo ""
  echo "     Converting file to json..."
  ruby -ryaml -rjson -e 'puts JSON.pretty_generate(YAML.load(ARGF))' < $y > $y.json
  echo "     Done converting file to json."
  echo ""
  echo "          Extracting CA's from this JSON file..."
  for ca in `cat $y.json | jq -r '.credentials | map(select(.type == "certificate")) | map(select(.value.ca == .value.certificate)) | .[].name'`
  do
    echo $ca
    # then get the PEM data and feed to openssl to get expiration date
    cat $y.json | jq -r --arg ca "$ca" '.credentials | map(select(.type == "certificate")) | map(select(.name==$ca)) | .[].value.certificate' | openssl x509 -dates -noout | grep notAfter
  done
  echo "          Done extracting CA's from this JSON file."
  echo ""
  echo "          Extracting Certificates from this JSON file..."
  for cert in `cat $y.json | jq -r '.credentials | map(select(.type == "certificate")) | map(select(.value.ca != .value.certificate)) | .[].name'`
  do
    echo $cert
    cat $y.json | jq -r --arg cert "$cert" '.credentials | map(select(.type == "certificate")) | map(select(.name==$cert)) | .[].value.certificate' | openssl x509 -dates -noout | grep notAfter
  done
  echo "          Done extracting Certificates from this JSON file."
  echo ""
  echo "     Done processing $y."
  echo "===================================================================="
done
echo ""
echo "Done processing all files."
