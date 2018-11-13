KEY_DIR="${HOME}/dockerkeys"
LDAP_CERT_DN="/CN=openldap/O=ibm/C=us"
POSTGRES_CERT_DN="/CN=postgresql/O=ibm/C=us"

if [ ! -d "$KEY_DIR" ]; then mkdir $KEY_DIR; fi
if [ ! -d "$KEY_DIR/openldap" ]; then mkdir $KEY_DIR/openldap; fi
if [ ! -d "$KEY_DIR/postgresql" ]; then mkdir $KEY_DIR/postgresql; fi

if [ ! -f "$KEY_DIR/openldap/ldap.key" ] || [ ! -f "$KEY_DIR/openldap/ldap.crt" ]
then
	echo "Creating LDAP certificate files"
  openssl req -x509 -newkey rsa:4096 -keyout $KEY_DIR/openldap/ldap.key -out $KEY_DIR/openldap/ldap.crt -days 3650 -subj $LDAP_CERT_DN -nodes
else
	echo "LDAP certificate files found - using existing certificate files"
fi

# Same for dhparam.pem file
if [ ! -f "$KEY_DIR/openldap/dhparam.pem" ]
then
	echo "Creating LDAP dhparam.pem"
	openssl dhparam -out "$KEY_DIR/openldap/dhparam.pem" 2048
else
	echo "LDAP dhparam.pem file found - using existing file"
fi

cp "$KEY_DIR/openldap/ldap.crt" "$KEY_DIR/openldap/ca.crt"

if [ ! -f "$KEY_DIR/postgresql/postgres.key" ] || [ ! -f "$KEY_DIR/postgresql/postgres.crt" ]
then
	echo "Creating postgres certificate files"
  openssl req -x509 -newkey rsa:4096 -keyout $KEY_DIR/postgresql/postgres.key -out $KEY_DIR/postgresql/postgres.crt -days 3650 -subj $POSTGRES_CERT_DN -nodes
else
	echo "Postgres certificate files found - using existing certificate files"
fi

cat  "$KEY_DIR/postgresql/postgres.crt" "$KEY_DIR/postgresql/postgres.key" > "$KEY_DIR/postgresql/server.pem"
