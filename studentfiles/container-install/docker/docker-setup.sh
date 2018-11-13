DOCKERSHARE=${HOME}/dockershare
KEY_DIR=${DOCKERSHARE}/dockerkeys
DOCKER_KEY_DIR=${HOME}/dockerkeys

if [ ! -d "$DOCKERSHARE" ]; then mkdir $DOCKERSHARE; fi
if [ ! -d "$KEY_DIR" ]; then mkdir $KEY_DIR; fi

if [ ! -f "$DOCKER_KEY_DIR/openldap/ldap.key" ] || [ ! -f "$DOCKER_KEY_DIR/openldap/ldap.crt" ] || [ ! -f "$DOCKER_KEY_DIR/openldap/ca.crt" ] || [ ! -f "$DOCKER_KEY_DIR/openldap/dhparam.pem" ] || [ ! -f "$DOCKER_KEY_DIR/postgresql/server.pem" ]
then
        echo "Not all files created; calling creation script..."
        ../common/create-ldap-and-postgres-keys.sh
fi

if [ ! -f "$KEY_DIR/openldap/ldap.key" ] || [ ! -f "$KEY_DIR/openldap/ldap.crt" ] || [ ! -f "$KEY_DIR/openldap/ca.crt" ] || [ ! -f "$KEY_DIR/openldap/dhparam.pem" ] || [ ! -f "$KEY_DIR/postgresql/server.pem" ]
then
        echo "Key copy not created; copying now..."
	cp -R $DOCKER_KEY_DIR/* $KEY_DIR
fi

docker network create isam
docker volume create isamconfig
docker volume create libldap
docker volume create libsecauthority
docker volume create ldapslapd
docker volume create pgdata

docker run -t -d --restart always -v pgdata:/var/lib/postgresql/data -v ${KEY_DIR}/postgresql:/var/local -e POSTGRES_USER=postgres -e POSTGRES_PASSWORD=Passw0rd -e POSTGRES_DB=isam -e POSTGRES_SSL_KEYDB=/var/local/server.pem --hostname postgresql --name postgresql --network isam ibmcom/isam-postgresql:9.0.5.0

docker run -t -d --restart always -v libldap:/var/lib/ldap -v ldapslapd:/etc/ldap/slapd.d -v libsecauthority:/var/lib/ldap.secAuthority -v ${KEY_DIR}/openldap:/container/service/slapd/assets/certs --hostname openldap --name openldap -e LDAP_DOMAIN=ibm.com -e LDAP_ADMIN_PASSWORD=Passw0rd -e LDAP_CONFIG_PASSWORD=Passw0rd -p 192.168.42.141:1636:636 --network isam ibmcom/isam-openldap:9.0.5.0 --copy-service

docker run -t -d --restart always -v isamconfig:/var/shared --hostname isamconfig --name isamconfig --cap-add SYS_PTRACE --cap-add SYS_RESOURCE -e CONTAINER_TIMEZONE=Europe/London -e ADMIN_PWD=Passw0rd -p 192.168.42.141:443:9443 -e SERVICE=config --network isam store/ibmcorp/isam:9.0.5.0

docker run -t -d --restart always -v isamconfig:/var/shared --hostname isamwrprp1 --name isamwrprp1 --cap-add SYS_PTRACE --cap-add SYS_RESOURCE -e CONTAINER_TIMEZONE=Europe/London -p 192.168.42.142:443:443 -e SERVICE=webseal -e INSTANCE=rp1 -e AUTO_RELOAD_FREQUENCY=5 --network isam store/ibmcorp/isam:9.0.5.0

docker run -t -d --restart always -v isamconfig:/var/shared --hostname isamruntime --name isamruntime --cap-add SYS_PTRACE --cap-add SYS_RESOURCE -e CONTAINER_TIMEZONE=Europe/London -p 192.168.42.141:1443:443 -e SERVICE=runtime -e AUTO_RELOAD_FREQUENCY=5 --network isam store/ibmcorp/isam:9.0.5.0

docker run -t -d --restart always -v isamconfig:/var/shared --hostname isamdsc --name isamdsc --cap-add SYS_PTRACE --cap-add SYS_RESOURCE -e CONTAINER_TIMEZONE=Europe/London -p 192.168.42.141:8443:443 -e SERVICE=dsc -e INSTANCE=1 -e AUTO_RELOAD_FREQUENCY=5 --network isam store/ibmcorp/isam:9.0.5.0

