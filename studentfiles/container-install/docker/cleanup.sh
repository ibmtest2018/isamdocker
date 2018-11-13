docker rm -fv isamwrprp1
docker rm -fv isamdsc
docker rm -fv isamruntime
docker rm -fv isamconfig
docker rm -fv openldap
docker rm -fv postgresql
docker volume rm isamconfig
docker volume rm libldap
docker volume rm libsecauthority
docker volume rm ldapslapd
docker volume rm pgdata
docker network rm isam
echo "Done."

