#/bin/bash

ROOT=$PWD
SITES=$ROOT/sites/
CERTS=$PWD/certs


# Change to site dir
cd $SITES/$1

# Get variables from .env
set -o allexport; source .env; set +o allexport

cd $ROOT;

FILE=CERTS/${DOMAIN}.pem
CURRENT_SITE=$SITES/$1

if [ ! -d $CURRENT_SITE ]; then
	echo 'Site not found.'
	exit 1;
fi

# Certs exist?
if [ ! -d $CERTS ]; then
	mkdir $CERTS 
fi

# Check if certificate exists
if [ ! -f $FILE ]; then
	cd $CERTS 
	mkcert ${DOMAIN} 
fi

# Copy certificates
docker cp CERTS/${DOMAIN}-key.pem nginx-proxy:/etc/nginx/certs/${DOMAIN}.key
docker cp CERTS/${DOMAIN}.pem nginx-proxy:/etc/nginx/certs/${DOMAIN}.crt

cd $CURRENT_SITE

# Reload nginx
docker exec nginx-proxy nginx -s reload

# Run docker compose
docker-compose up --build