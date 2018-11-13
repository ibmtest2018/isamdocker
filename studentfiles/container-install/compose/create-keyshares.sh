DOCKERSHARE=${HOME}/dockershare
KEY_DIR=${DOCKERSHARE}/composekeys
DOCKER_KEY_DIR=${HOME}/dockerkeys

if [ ! -d "$DOCKERSHARE" ]; then mkdir $DOCKERSHARE; fi
if [ ! -d "$KEY_DIR" ]; then mkdir $KEY_DIR; fi

if [ ! -f "$DOCKER_KEY_DIR/openldap/ldap.key" ] || [ ! -f "$DOCKER_KEY_DIR/openldap/ldap.crt" ] || [ ! -f "$DOCKER_KEY_DIR/openldap/ca.crt" ] || [ ! -f "$DOCKER_KEY_DIR/openldap/dhparam.pem" ] || [ ! -f "$DOCKER_KEY_DIR/postgresql/server.pem" ]
then
        echo "Not all files created; calling creation script..."
        ../common/create-ldap-and-postgres-keys.sh
fi

echo "Creating key shares at $KEY_DIR"
cp -R $DOCKER_KEY_DIR/* $KEY_DIR
echo "Done."
