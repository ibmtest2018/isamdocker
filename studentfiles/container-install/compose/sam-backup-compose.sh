#!/bin/bash

# Set file locations
SF=${HOME}/studentfiles
PROJECT=${SF}/container-install/compose/iamlab
YAML=${PROJECT}/docker-compose.yaml
KEYS=${HOME}/dockerkeys

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# CD to project to pick up .env file
CUR_DIR=`pwd`
cd ${PROJECT}

# Get docker container ID for isamconfig container
ISAMCONFIG="$(docker-compose -f ${YAML} ps -q isamconfig)"

# Copy the current snapshots from isamconfig container
SNAPSHOTS=`docker exec ${ISAMCONFIG} ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
docker cp ${ISAMCONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR
done

# Get docker container ID for openldap container
OPENLDAP="$(docker-compose -f ${YAML} ps -q openldap)"

# Extract LDAP Data from OpenLDAP
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="$(docker-compose -f ${YAML} ps -q postgresql)"
docker exec -- ${POSTGRESQL} su postgres -c "/usr/local/bin/pg_dump isam" > $TMPDIR/isam.db

cp -R ${KEYS} ${TMPDIR}
cd ${CUR_DIR}
tar -cvf sam-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
