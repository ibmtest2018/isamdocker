#!/bin/bash

# Set file locations
KEYS=${HOME}/dockerkeys

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

# Get docker container ID for isamconfig container
ISAMCONFIG="$(kubectl get --no-headers=true pods -l app=isamconfig -o custom-columns=:metadata.name)"

# Copy the current snapshots from isamconfig container
SNAPSHOTS=`kubectl exec ${ISAMCONFIG} ls /var/shared/snapshots`
for SNAPSHOT in $SNAPSHOTS; do
kubectl cp ${ISAMCONFIG}:/var/shared/snapshots/$SNAPSHOT $TMPDIR
done

# Get docker container ID for openldap container
OPENLDAP="$(kubectl get --no-headers=true pods -l app=openldap -o custom-columns=:metadata.name)"

# Extract LDAP Data from OpenLDAP
kubectl exec ${OPENLDAP} -- ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "secAuthority=Default" -s sub "(objectclass=*)" > $TMPDIR/secauthority.ldif
kubectl exec ${OPENLDAP} -- ldapsearch -H "ldaps://localhost:636" -L -D "cn=root,secAuthority=Default" -w "Passw0rd" -b "dc=ibm,dc=com" -s sub "(objectclass=*)" > $TMPDIR/ibmcom.ldif

# Get docker container ID for postgresql container
POSTGRESQL="$(kubectl get --no-headers=true pods -l app=postgresql -o custom-columns=:metadata.name)"
kubectl exec ${POSTGRESQL} -- su postgres -c "/usr/local/bin/pg_dump isam" > $TMPDIR/isam.db

cp -R ${KEYS} ${TMPDIR}

tar -cf sam-backup-$RANDOM.tar -C ${TMPDIR} .
rm -rf ${TMPDIR}
echo Done.
