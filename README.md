# isamdocker

These files are provided as-is with no warranty expressed or implied.  Use at your own risk.
These files are only intended for use in a sandboxed learning environment; they might break or delete stuff.

# Common Requirements and Setup

Copy the studentfiles directory to your home directory so that you have $HOME/studentfiles containing config-archives and container-install directories.  If you want to store the scripts elsewhere you will need to modify the SF environment variable whereever it appears in the scripts.

These scripts expect to have write access to $HOME and /tmp.

These scripts will create directories at $HOME/dockerkeys and $HOME/dockershare.  If you want to use different directories then you'll need to modify the environment variables whereever they appear in the scripts.

You will need to have an account on Docker Store.  You will need to register for the store/ibmcorp/isam image in the store.

All passwords set by these scripts are `Passw0rd`.  Obviously this is not a secure password!

# Create Keystores
Before running any other scripts, run `studentfiles/container-install/common/create-ldap-and-postgres-keys.sh`

This will create the $HOME/dockerkeys directory and populate it with keystores for PostgreSQL and OpenLDAP containers.

# Native Docker
To set up a native Docker environment, use the files in studentfiles/container-install/docker.

These scripts will create the $HOME/dockershare directory.

These scripts assume you have the following IP addresses available locally on your Docker system:
- 192.168.42.141
- 192.168.42.142

If you want to use other local IP addresses then you'll need to modify the scripts.

First, use `docker login` to log in to Docker.

Then run `./docker-setup.sh` script to create docker containers.

You can now connect to the ISAM LMI at https://192.168.42.141

To clean up the docker resources created, run the `./cleanup.sh` script.

# Docker Compose
To set up an environment with docker-compose, use the files in studentfiles/container-install/compose.

These scripts will create the $HOME/dockershare directory.

These scripts assume you have the following IP addresses available locally on your Docker system:
- 192.168.42.141
- 192.168.42.142

If you want to use other local IP addresses then you'll need to modify the scripts.

First, use `docker login` to log in to Docker.

Run `./create-keyshares.sh` to copy keys to $HOME/dockershare/composekeys directory

Change directory to the `iamlab` directory.

Run command `docker-compose up -d` to create containers.

You can now connect to the ISAM LMI at https://192.168.42.141

To clean up the docker resources created, run `docker-compose down -v` command.

# Kubernetes
To set up an environment using Kubernetes, use the files in studentfiles/container-install/kubernetes.

These scripts assume that you have the `kubectl` utility installed and that is is configured to talk to your cluster.

First, run `./create-docker-store-secret.sh` command and provide your Docker credentials.

Next, run `./create-secrets.sh` command to create the secrets required for the environment.

Finally, run `kubectl create -f <YAML file>` to define the resources required.

There are YAML files for the following environments:
- Minikube (sam-minikube.yaml)
- IBM Cloud (sam-ibmcloud.yaml)
- Google (sam-google.yaml)

Once all pods are running, you can run the `./lmi-access.sh` script to start a port-forward session for access to the LMI.
With this running, you can access LMI using at https://localhost:9443

To access the Reverse Proxy you will need to determine an External IP for a Node in the cluster and then connnect to this using https://<Node External IP>:30443.

For Google, access to a NodePort requires the following filewall rule to be created:
`gcloud compute firewall-rules create isamwrp-node-port --allow tcp:30443`

# OpenShift
This is a work in progress.  OpenShift is not supported by Access Manager at this time.

# Backup and Restore

To backup the state of your environment, use the `./sam-backup....sh` script in the directory for the environment you're using.  The backup tar file created will contain:
- Content of the $HOME/dockerkeys directory
- OpenLDAP directory content
- PostgreSQL database content
- Configuration snapshot from ISAM config container

To restore from a backup, perform these steps:

1. Delete the $HOME/dockerkeys and $HOME/dockershare directories
1. Run `studentfiles/container-install/common/restore-keys.sh <archive tar file>`
1. Complete setup for the environment you want to create (until containers are running)
1. Run `./sam-restore....sh <archive tar file>` to restore configuration.

Note that you will see errors during the restore when it attempts to create LDAP and DB objects that already exist.
