KEY_DIR="${HOME}/dockerkeys"

if [ ! -f "$KEY_DIR/openldap/ldap.key" ] || [ ! -f "$KEY_DIR/openldap/ldap.crt" ] || [ ! -f "$KEY_DIR/openldap/ca.crt" ] || [ ! -f "$KEY_DIR/openldap/dhparam.pem" ] || [ ! -f "$KEY_DIR/postgresql/server.pem" ]
then
	echo "Not all files created; calling creation script..."
	../common/create-ldap-and-postgres-keys.sh
fi

# Create secret for TLS certificates used by this container
echo "Deleting openldap-keys Secret"
kubectl delete secret openldap-keys > /dev/null 2>&1
echo "Creating OpenLDAP SSL Keys as a Secret"
kubectl create secret generic "openldap-keys" --from-file "$KEY_DIR/openldap/ldap.crt" --from-file "$KEY_DIR/openldap/ldap.key" --from-file "$KEY_DIR/openldap/ca.crt" --from-file "$KEY_DIR/openldap/dhparam.pem"

echo "Deleting postgresql-keys Secret"
kubectl delete secret postgresql-keys > /dev/null 2>&1
echo "Creating server.pem as a Secret"
kubectl create secret generic postgresql-keys --from-file "$KEY_DIR/postgresql/server.pem"

echo "Deleting samadmin Secret"
kubectl delete secret samadmin > /dev/null 2>&1
echo "Creating samadmin Secret"
kubectl create secret generic samadmin
kubectl patch secret/samadmin -p '{"data":{"adminpw":"UGFzc3cwcmQ="}}'

echo "Deleting configreader Secret"
kubectl delete secret configreader > /dev/null 2>&1
echo "Creating configreader Secret"
kubectl create secret generic configreader
kubectl patch secret/configreader -p '{"data":{"cfgsvcpw":"UGFzc3cwcmQ="}}'
echo "Done."
