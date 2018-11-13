osadminid=system
osadminpw=admin

echo "Creating isam Service Account"
oc create serviceaccount isam

echo "Creating isam Security Constraint"
oc create -f isam-scc.yaml --as ${osadminid}:${osadminpw}

echo "Adding isam service account to isam Security Constraint"
oc adm policy add-scc-to-user isam -z isam --as ${osadminid}:${osadminpw}

echo "Done."


