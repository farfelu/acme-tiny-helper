#!/bin/bash

# make current directory the same where the script file is
cd "$(dirname "$0")"

# check if acme-tiny exists
if [[ ! -e acme-tiny/acme_tiny.py ]]
then
    echo acme tiny not found
    echo get it from https://github.com/diafygi/acme-tiny
    exit 1
fi

if [[ ! -e config.cfg ]]
then
    echo no config.cfg file found
    exit 1
fi

# load config variables
. config.cfg

# create directories where stuff is stored
mkdir keys 2> /dev/null
mkdir requests 2> /dev/null
mkdir certificates 2> /dev/null

# check if we are using the staging server, otherwise use default of acme-tiny
CA=
if [[ $USESTAGING -eq 1 ]]
then
    echo
    echo WARNING: USING STAGING/TEST SERVER
    echo
    CA="--ca https://acme-staging.api.letsencrypt.org"
fi

accountfile=keys/account.key
haserror=0

# if no account private key is found, generate one
if [[ ! -e $accountfile ]]
then
    echo no account private key found. generating $accountfile
    openssl genrsa $KEYSIZE > $accountfile
fi

# nginx requires a full chain
echo download letsencrypt certificate for chaining
wget -O - https://letsencrypt.org/certs/lets-encrypt-x1-cross-signed.pem > intermediate.pem


# loop through each domain
for domainlist in "${DOMAINS[@]}"
do
    # grab the first domain
    domain=`echo ${domainlist} | cut -d, -f1`
    
    # for alternative names we need to put DNS in front of every domain
    # so simply relpace the comma with ",DNS:" and add it manually for the first
    SAN=DNS:`echo ${domainlist} | sed 's/\,/,DNS:/g'`
    
    echo
    echo
    echo Domain: ${domain}
    echo SAN: ${SAN}
    echo
    
    keyfile=keys/$domain.key
    requestfile=requests/$domain.csr
    certdir=certificates/$domain # the first domain name will be used for the directory name where the certificates will be stored
    
    mkdir -p $certdir 2> /dev/null
    
    # if we don't have a private key for this domain yet, create one
    if [[ ! -e $keyfile ]]
    then
        echo no domain private key found. generating $keyfile
        openssl genrsa $KEYSIZE > $keyfile
    fi
    
    echo generate certificate signing request
    openssl req -new -sha256 -key $keyfile -subj "/" -reqexts SAN -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=${SAN}")) > $requestfile
    echo
    echo running acme_tiny.py
    python acme-tiny/acme_tiny.py $CA --account-key $accountfile --csr $requestfile --acme-dir $WEBROOT > $certdir/cert.crt
    
    # check if any errors happened
    if [[ $? -ne 0 ]]
    then
        haserror=1
        continue
    fi
    
    # create chained certificate by just concatenating them
    cat $certdir/cert.crt intermediate.pem > $certdir/fullchain.pem
done

# cleanup
rm intermediate.pem

if [[ $haserror -ne 0 ]]
then
    echo
    echo
    echo ERRORS HAPPENED
    echo check above
    exit 1
fi

echo
echo all done.
