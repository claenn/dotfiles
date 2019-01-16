#!/bin/bash
#  crypten - a script to encrypt files using openssl

INAME=$1
ONAME=$2

if [[ -z "$INAME" ]]; then
echo "crypten []"
echo " – crypten is a script to encrypt files using aes"
exit;
fi

if [[ -z "$ONAME" ]]; then
openssl enc -aes-256-cbc -salt -in "$INAME" -out "$INAME"
else
openssl enc -aes-256-cbc -salt -in "$INAME" -out "$ONAME"
fi

