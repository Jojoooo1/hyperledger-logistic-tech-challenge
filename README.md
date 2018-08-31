## Project created for Logistic Tech Challenge organized and hosted by [Intelipost](https://www.intelipost.com.br/)
In July 2018, the 1st edition of the Intelipost Logistics Tech Challenge happened in São Paulo!

Organized by Intelipost, in partnership with Oracle Brasil and Abralog, 50 participants had been selected for a 2-day event in Hackathon format, for developing a solutions using Blockchain technology for logistics.

### Technical approach
The project has been developed using Hyperledger Fabric and Hyperledger composer. The network is build on top of a swarn network for being able to have 3 nodes running on different places.<br/>
##### Script approach: <br/>
`build.sh`<br/> 
This script will generate crypto and channel artifacts necessary for creating the network. It will also create a toSendAfterBuild folder containing those artifacts for other node to be able to start their corresponding docker container. (don't forget to change BIN_DIR to your corresponding path)<br/><br/>
`startFabric_x.sh`<br/> 
Script to start docker container.<br/><br/>
`initIdentityAndChainCode_1.sh`<br/>
This script create all the identities and instantiate the smart contract on node 1, 2 & 3. It has been created for instantiating everything from node 1. When executed it will create a toSendAfterIdentityCreation folder to send to peer 2 & 3 containing admin identity card. `initIdentityAndChainCode_2.sh` & `initIdentityAndChainCode_3.sh` are just for importing the card created by `initIdentityAndChainCode_1.sh` and placed in toSendAfterIdentityCreation.

### Create swarm<br/>
Initialize swarm manager on PC1:<br/>
`docker swarm init --advertise-addr 192.168.1.31` (in terminal get your ip: ip addr  => should show inet 192.168.1.31)<br/>
After tipping the command it will show you something similar as `docker swarm join --token SWMTKN-1-1ymnwhc93p9hp8hyu3m1fb7p64alnvhbm1h5howee3755idwuo-0j5bj0jcrswbskl92vmi8eu3x 192.168.1.31` <br/><br/>


On PC2, PC3: Join the swarm as worker by coping the command showed after swarm init:<br/>
`docker swarm join --token SWMTKN-1-1ymnwhc93p9hp8hyu3m1fb7p64alnvhbm1h5howee3755idwuo-0j5bj0jcrswbskl92vmi8eu3x 192.168.1.31`<br/><br/>


Create docker network <br/>
`docker network create --attachable --driver overlay my-net`<br/>

Open Port on your different host <br/>
`sudo ufw allow 2377/tcp && sudo ufw allow 7946/tcp && sudo ufw allow 7946/udp && sudo ufw allow 4789/udp`<br/>
(TCP port 2377 for cluster management communications, TCP and UDP port 7946 for communication among nodes UDP port 4789 for overlay network traffic)

### Mount the project<br/>
1. Build the config `build.sh`
2. Send file created in folder toSendAfterBuild to host 2 & 3
3. Start `startFabric_1.sh` in host1, start `StartFabric_2.sh` in host 2, `StartFabric_3.sh` in host 3
4. Create the identity and chaincode instantiation by executing `initIdentityAndChainCode_1.sh` in host 1
5. Send the card created in folder toSendAfterIdentityCreation to corresponding host and copy it in the same folder as `initIdentityAndChainCode_x.sh`
6. Start `initIdentityAndChainCode_2.sh` in host 2, `initIdentityAndChainCode_3.sh` in host 3
