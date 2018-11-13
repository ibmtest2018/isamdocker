#!/bin/bash

# Set file locations
KEYS=${HOME}/dockerkeys

# Create a temporary working directory
TMPDIR=/tmp/backup-$RANDOM$RANDOM
mkdir $TMPDIR

if [ $# -ne 1 ]
then
  echo "Usage: $0 <archive file>"
  exit 1
fi

if [ ! -f "$1" ]
then
  echo "File not found - $1"
  exit 1
fi
 
if [ -d "${KEYS}" ]
then
  echo "${KEYS} already exists.  Aborting."
  exit 1
fi

tar -xf $1 -C ${TMPDIR}
cp -R ${TMPDIR}/dockerkeys ${HOME}

rm -rf ${TMPDIR}
echo Done.
