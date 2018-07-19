#!/bin/bash

# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Exit on first error, print all commands.
set -e

DIR=$PWD
FABRIC_START_TIMEOUT=15

DOMAIN_ORG=(intelipost.shipper.logistic.com carriers.transporter.logistic.com correios.transporter.logistic.com)
DOMAIN_ORDERER=intelipost.orderer.logistic.com

CONFIGTX_ORGANISATION3_NAME=Correios
CONFIGTX_ORGANISATION3_ID=CorreiosMSP
CHANNEL_NAME=channel

COUCHDB_NAME=couchdb3
# Removed composer folder caused by tar archive

# Get private key file name of CA 
cd crypto-config/peerOrganizations/${DOMAIN_ORG[2]}/ca/
PRIV_KEY_CA2=$(ls *_sk)
cd $DIR

docker run -d --network="my-net" --name ca.${DOMAIN_ORG[2]} -p 8054:7054 \
-e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
-e FABRIC_CA_SERVER_CA_NAME=ca.${DOMAIN_ORG[2]} \
-e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/$PRIV_KEY_CA2 \
-e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.${DOMAIN_ORG[2]}-cert.pem \
-v $(pwd)/crypto-config/peerOrganizations/${DOMAIN_ORG[2]}/ca/:/etc/hyperledger/fabric-ca-server-config \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
hyperledger/fabric-ca:x86_64-1.1.0 sh -c 'fabric-ca-server start -b admin:adminpw -d'


docker run -d --network="my-net" --name $COUCHDB_NAME -p 6984:5984 \
-e COUCHDB_USER= -e COUCHDB_PASSWORD= \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
hyperledger/fabric-couchdb:0.4.8


docker run -d --link ${DOMAIN_ORDERER}:${DOMAIN_ORDERER} --link peer0.${DOMAIN_ORG[0]}:peer0.${DOMAIN_ORG[0]} --link peer0.${DOMAIN_ORG[1]}:peer0.${DOMAIN_ORG[1]} \
--network="my-net" --name peer0.${DOMAIN_ORG[2]} -p 8051:7051 -p 8053:7053 \
-e CORE_LOGGING_LEVEL=debug \
-e CORE_CHAINCODE_LOGGING_LEVEL=DEBUG \
-e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
-e CORE_PEER_ID=peer0.${DOMAIN_ORG[2]} \
-e CORE_PEER_ADDRESS=peer0.${DOMAIN_ORG[2]}:7051 \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
-e CORE_PEER_LOCALMSPID=${CONFIGTX_ORGANISATION3_ID} \
-e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/peer/msp \
-e CORE_LEDGER_STATE_STATEDATABASE=CouchDB \
-e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=${COUCHDB_NAME}:5984 \
-e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME= \
-e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD= \
-e CORE_NEXT=true \
-e CORE_PEER_ENDORSER_ENABLED=true \
-e CORE_PEER_PROFILE_ENABLED=true \
-e CORE_PEER_COMMITTER_LEDGER_ORDERER=${DOMAIN_ORDERER}:7050 \
-e CORE_PEER_GOSSIP_ORGLEADER=true \
-e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.${DOMAIN_ORG[2]}:7051 \
-e CORE_PEER_GOSSIP_IGNORESECURITY=true \
-e CORE_PEER_GOSSIP_USELEADERELECTION=false \
-v /var/run/:/host/var/run/ \
-v $(pwd)/channel-artifacts:/etc/hyperledger/configtx \
-v $(pwd)/crypto-config/peerOrganizations/${DOMAIN_ORG[2]}/peers/peer0.${DOMAIN_ORG[2]}/msp:/etc/hyperledger/peer/msp \
-v $(pwd)/crypto-config/peerOrganizations/${DOMAIN_ORG[2]}/users:/etc/hyperledger/msp/users \
-w /opt/gopath/src/github.com/hyperledger/fabric/peer \
hyperledger/fabric-peer:x86_64-1.1.0 peer node start



# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
echo "sleeping for ${FABRIC_START_TIMEOUT} seconds to wait for fabric to complete start up"
sleep ${FABRIC_START_TIMEOUT}


# Fetch block config
docker exec peer0.${DOMAIN_ORG[2]} peer channel fetch 0 ${CHANNEL_NAME}.block -c $CHANNEL_NAME -o ${DOMAIN_ORDERER}:7050

# Join peer0.${DOMAIN_ORG[2]} to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@${DOMAIN_ORG[2]}/msp" \
peer0.${DOMAIN_ORG[2]} peer channel join -b ${CHANNEL_NAME}.block

# Update the channel definition to define the anchor peer for Org2 as peer0.${DOMAIN_ORG[2]}
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@${DOMAIN_ORG[2]}/msp" \
peer0.${DOMAIN_ORG[2]} peer channel update -o ${DOMAIN_ORDERER}:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/${CONFIGTX_ORGANISATION3_NAME}anchors.tx 



