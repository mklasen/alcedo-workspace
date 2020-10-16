#/bin/bash

ROOT=$PWD
SITES=$ROOT/sites/
CERTS=$PWD/certs
FILE=CERTS/${domain}.pem
CURRENT_SITE=$SITES/$1

if [ ! -d $CURRENT_SITE ]; then
	echo 'Site not found.'
	exit 1;
fi

# Change to site dir
cd $SITES/$1

# Get variables from .env
set -o allexport; source .env; set +o allexport

# Certs exist?
if [ ! -d $CERTS ]; then
	mkdir $CERTS 
fi

# Check if certificate exists
if [ ! -f $FILE ]; then
	cd $CERTS 
	mkcert ${domain} 
fi

# Copy certificates
docker cp ${domain}-key.pem nginx-proxy:/etc/nginx/certs/${domain}.key
docker cp ${domain}.pem nginx-proxy:/etc/nginx/certs/${domain}.crt

cd $CURRENT_SITE

# Reload nginx
docker exec nginx-proxy nginx -s reload

# Run docker compose
docker-compose up --build