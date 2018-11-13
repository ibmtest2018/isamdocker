docker build -t iamlab/liberty:1.0 build/wlp

mkdir $HOME/dockershare/wlp-metadata

docker run -d --restart always -p 192.168.42.142:9443:9443 -v $HOME/dockershare/wlp-metadata:/config/metadata --name wlp --network isam --hostname  wlp iamlab/liberty:1.0
