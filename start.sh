#/bin/bash

ROOT=$PWD
SITES=$ROOT/sites/
CERTS=$PWD/certs


# Change to site dir
cd $SITES/$1

# Get variables from .env
set -o allexport; source .env; set +o allexport

cd $ROOT;


CURRENT_SITE=$SITES$1

if [ ! -d $CURRENT_SITE ]; then
	echo 'Site not found.'
	exit 1;
fi


# Certs directory exist?
if [ ! -d $CERTS ]; then
	mkdir $CERTS 
fi

IFS=',' read -ra ADDR <<< "$DOMAINS"
for i in "${ADDR[@]}"; do
	# Check if certificate exists
	FILE=$CERTS/${i}.pem
	cd $CERTS 
	mkcert ${i} 

	# Copy certificates
	docker cp $CERTS/${i}-key.pem nginx-proxy:/etc/nginx/certs/${i}.key
	docker cp $CERTS/${i}.pem nginx-proxy:/etc/nginx/certs/${i}.crt
done


cd $CURRENT_SITE

# Reload nginx
docker exec nginx-proxy nginx -s reload

# Run docker compose
docker-compose up -d --build


# Run container specific scripts
if [ ! -f $CURRENT_SITE/config/init.sh ]; then
	sh $CURRENT_SITE/config/init.sh
fi