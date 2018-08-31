## Project created for Logistic Tech Challenge organized by [Intelipost](https://www.intelipost.com.br/)
In July 2018, the 1st edition of the Intelipost Logistics Tech Challenge happened in São Paulo!

Organized by Intelipost, in partnership with Oracle Brasil and Abralog, 50 participants had been selected for a 2-day event in Hackathon format, for developing a solutions using Blockchain technology for logistics.

### Technical approach
The project has been developed using Hyperledger Fabric and Hyperledger composer. The network is build on top of a swarn network for being able to have 3 nodes running on different places.<br/><br/>
Script approach: <br/>
`build.sh`: Change bin path to your corresponding path.<br/> 
This script will generate crypto and channel artifacts necessary for creating the network. It will also create a toSendAfterBuild folder containing those artifacts for other node to be able to start their corresponding docker container.<br/>
`startFabric_x.sh` contain the script to start docker container.<br/>
`initIdentityAndChainCode_x.sh` will create all the identity to participate to the network and also instantiate the smart contract on node 2 & 3. It has been created for instantiating everything from node 1. When executed it will create a toSendAfterIdentityCreation folder to send to peer 2 & 3 containing admin identity card.

### Step to create the network
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

1. Build the config `build.sh`
2. Send file created in folder toSendAfterBuild to corresponding host
3. Start `startFabric_1.sh` in host1 
4. Start `StartFabric_2.sh` in host 2, `StartFabric_3.sh` in host 3
5. Create the identity and chaincode instantiation by executing `initIdentityAndChainCode_1.sh`
6. Send the card created in folder toSendAfterIdentityCreation to corresponding host and copy it in the same folder as `initIdentityAndChainCode_x.sh`
7. Start `initIdentityAndChainCode_2.sh` in host 2, `initIdentityAndChainCode_3.sh` in host 3
