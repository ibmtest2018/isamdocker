#!/bin/bash

# Set file locations
KEYS=${HOME}/dockerkeys

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# Get docker container ID for isamconfig container
ISAMCONFIG="isamconfig"

# Copy the current snapshots from isamconfig container
SNAPSHOTS=`docker exec ${ISAMCONFIG} ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
docker cp ${ISAMCONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR
done

# Get docker container ID for openldap container
OPENLDAP="openldap"

# Extract LDAP Data from OpenLDAP
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
docker exec -- ${OPENLDAP} ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="postgresql"
docker exec -- ${POSTGRESQL} su postgres -c "/usr/local/bin/pg_dump isam" > $TMPDIR/isam.db

cp -R ${KEYS} ${TMPDIR}

tar -cf sam-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
