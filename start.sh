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



	originalDomain=$i;
	generatedFileName=$i;

	# Check if certificate exists
	cd $CERTS 
	mkcert -cert-file ${generatedFileName}.pem -key-file ${generatedFileName}-key.pem ${DOMAINS//[,]/ }


	# Check for wildcards
	if [[ "$i" == *"*"* ]]; then
		# Wildcard
		generatedFileName=${originalDomain/\*/_wildcard};
		originalDomain=${originalDomain/\*./''};
	fi

	echo "docker cp $CERTS/${generatedFileName}-key.pem nginx-proxy:/etc/nginx/certs/${originalDomain}.key";
	echo "docker cp $CERTS/${generatedFileName}.pem nginx-proxy:/etc/nginx/certs/${originalDomain}.crt";

	# Copy certificates
	docker cp $CERTS/${generatedFileName}-key.pem nginx-proxy:/etc/nginx/certs/${originalDomain}.key
	docker cp $CERTS/${generatedFileName}.pem nginx-proxy:/etc/nginx/certs/${originalDomain}.crt

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