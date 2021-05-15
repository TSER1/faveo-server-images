#!/bin/bash


echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "FAVEO DB Creation Script"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#FLUSH PRIVILEGES;
#CREATE USER 'helpdeskuser'@'localhost' IDENTIFIED BY 'helpdesk';
#CREATE DATABASE helpdesk;
#GRANT ALL PRIVILEGES ON helpdesk.* TO 'helpdeskuser'@'localhost';


echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Installing openssl"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#yum install gcc -y
#wget https://www.openssl.org/source/openssl-1.0.2h.tar.gz
#tar -xvzf openssl-1.0.2h.tar.gz
#cd openssl-1.0.2h/
#./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl
#sudo make
#sudo make install
#sudo ln -s /usr/local/openssl/bin/openssl /usr/local/bin
openssl -version

echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
echo "Bash Script to Create an SSL Certificate Key and Request (CSR)"
echo "+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#Required
#domain=$1
domain="timesync.co.in"
commonname=$domain

echo "----------------------------------"
echo "Domain: ${domain}"
echo "----------------------------------"

echo "----------------------------------"
echo "Certificate data from company details"
echo "----------------------------------"
echo "country=IN
state=MH
locality=Pune
organization=TimesyncTechnology
organizationalunit=IT
email=admin@timesync.co.in"

country=IN
state=MH
locality=Pune
organization=TimesyncTechnology
organizationalunit=IT
email=admin@timesync.co.in

#Optional
password=dummypassword

if [ -z "$domain" ]
then
    echo "Argument not present."
    echo "Useage $0 [common name]"

    exit 99
fi

echo "----------------------------------"
echo "Generating key request for $domain"
echo "----------------------------------"

echo "----------------------------------"
echo "Generate a key"
echo "----------------------------------"
openssl genrsa -des3 -passout pass:$password -out $domain.key 2048 -noout

echo "----------------------------------"
echo "Remove passphrase from the key. Comment the line out to keep the passphrase"
echo "----------------------------------"
echo "Removing passphrase from key"
openssl rsa -in $domain.key -passin pass:$password -out $domain.key

echo "----------------------------------"
echo "Create the request"
echo "----------------------------------"
echo "Creating CSR"
openssl req -new -key $domain.key -out $domain.csr -passin pass:$password \
    -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

echo "---------------------------"
echo "-----Below is your CSR-----"
echo "---------------------------"
echo
cat $domain.csr

echo
echo "---------------------------"
echo "-----Below is your Key-----"
echo "---------------------------"
echo
cat $domain.key

echo
echo "---------------------------"
echo "-----Below is your CRT-----"
echo "---------------------------"
echo
openssl x509 -req -days 365 -in $domain.csr -signkey $domain.key -out $domain.crt

cat $domain.crt
