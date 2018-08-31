# Project created for Logistic Tech Challenge organized by [Intelipost](https://www.intelipost.com.br/)


# Hyperledger-composer-with-multiple-host-improved-build
hyperledger composer on multiple host

Create swarm:
On PC1: initialize the host as manager
	docker swarm init --advertise-addr 192.168.1.31 (in terminal get your ip: ip addr  => should show inet 192.168.1.31)

On PC2: join the swarm as worker
docker swarm join --token ************************************** 

Create network:
docker network create --attachable --driver overlay my-net

Open Port on your different host:
sudo ufw allow 2377/tcp && sudo ufw allow 7946/tcp && sudo ufw allow 7946/udp && sudo ufw allow 4789/udp

(TCP port 2377 for cluster management communications, TCP and UDP port 7946 for communication among nodes UDP port 4789 for overlay network traffic)

1. Build the config
2. Send file created in folder toSendAfterBuild to corresponding host
3. Start startFabric_1.sh in host1 
4. Start StartFabric_x.sh in hostx
5. Create the identity and chaincode instantiation by executing initIdentityAndChainCode_1.sh
6. Send the card created in folder toSendAfterIdentityCreation to corresponding host and copy it to folder orgx.example.com
7. Start initIdentityAndChainCode_x.sh
