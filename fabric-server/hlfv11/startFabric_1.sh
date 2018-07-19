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

DOMAIN_ORG1=intelipost.shipper.logistic.com

DOMAIN_ORDERER=intelipost.orderer.logistic.com
DOMAIN_ORDERER_WO_HOST=orderer.logistic.com

CONFIGTX_ORGANISATION1_NAME=IntelipostShipper
CONFIGTX_ORGANISATION1_ID=IntelipostShipperMSP
CONFIGTX_ORDER_NAME=IntelipostOrderer
CONFIGTX_ORDER_ID=IntelipostOrdererMSP

CHANNEL_NAME=channel

# Remove composer folder for other host

# Get private key file name of CA 
cd composer/crypto-config/peerOrganizations/${DOMAIN_ORG1}/ca/
PRIV_KEY_CA1=$(ls *_sk)
cd $DIR

docker run -d --network="my-net" --name ca.${DOMAIN_ORG1} -p 7054:7054 \
-e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server \
-e FABRIC_CA_SERVER_CA_NAME=ca.${DOMAIN_ORG1} \
-e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/$PRIV_KEY_CA1 \
-e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.${DOMAIN_ORG1}-cert.pem \
-v $(pwd)/composer/crypto-config/peerOrganizations/${DOMAIN_ORG1}/ca/:/etc/hyperledger/fabric-ca-server-config \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
hyperledger/fabric-ca:x86_64-1.1.0 sh -c 'fabric-ca-server start -b admin:adminpw -d'


docker run -d --network="my-net" --name $DOMAIN_ORDERER -p 7050:7050 \
-e ORDERER_GENERAL_LOGLEVEL=debug \
-e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 \
-e ORDERER_GENERAL_GENESISMETHOD=file \
-e ORDERER_GENERAL_GENESISFILE=/etc/hyperledger/configtx/genesis.block \
-e ORDERER_GENERAL_LOCALMSPID=${CONFIGTX_ORDER_ID} \
-e ORDERER_GENERAL_LOCALMSPDIR=/etc/hyperledger/msp/orderer/msp \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
-v $(pwd)/composer/channel-artifacts:/etc/hyperledger/configtx \
-v $(pwd)/composer/crypto-config/ordererOrganizations/${DOMAIN_ORDERER_WO_HOST}/orderers/${DOMAIN_ORDERER}/msp:/etc/hyperledger/msp/orderer/msp \
-w /opt/gopath/src/github.com/hyperledger/fabric \
hyperledger/fabric-orderer:x86_64-1.1.0 orderer
#-e ORDERER_GENERAL_TLS_ENABLED=false \

docker run -d --network="my-net" --name couchdb1 -p 5984:5984 \
-e COUCHDB_USER= -e COUCHDB_PASSWORD= \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
hyperledger/fabric-couchdb:0.4.8


docker run -d --link ${DOMAIN_ORDERER}:${DOMAIN_ORDERER} \
--network="my-net" --name peer0.${DOMAIN_ORG1} -p 7051:7051 -p 7053:7053 \
-e CORE_LOGGING_LEVEL=debug \
-e CORE_CHAINCODE_LOGGING_LEVEL=DEBUG \
-e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock \
-e CORE_PEER_ENDORSER_ENABLED=true \
-e CORE_PEER_ID=peer0.${DOMAIN_ORG1} \
-e CORE_PEER_ADDRESS=peer0.${DOMAIN_ORG1}:7051 \
-e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net \
-e CORE_PEER_LOCALMSPID=${CONFIGTX_ORGANISATION1_ID} \
-e CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/peer/msp \
-e CORE_LEDGER_STATE_STATEDATABASE=CouchDB \
-e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb1:5984 \
-e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME= \
-e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD= \
-e CORE_NEXT=true \
-e CORE_PEER_PROFILE_ENABLED=true \
-e CORE_PEER_COMMITTER_LEDGER_ORDERER=${DOMAIN_ORDERER}:7050 \
-e CORE_PEER_GOSSIP_IGNORESECURITY=true \
-e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.${DOMAIN_ORG1}:7051 \
-e CORE_PEER_TLS_ENABLED=false \
-e CORE_PEER_GOSSIP_USELEADERELECTION=false \
-e CORE_PEER_GOSSIP_ORGLEADER=true \
-v /var/run/:/host/var/run/ \
-v $(pwd)/composer/channel-artifacts:/etc/hyperledger/configtx \
-v $(pwd)/composer/crypto-config/peerOrganizations/${DOMAIN_ORG1}/peers/peer0.${DOMAIN_ORG1}/msp:/etc/hyperledger/peer/msp \
-v $(pwd)/composer/crypto-config/peerOrganizations/${DOMAIN_ORG1}/users:/etc/hyperledger/msp/users \
-w /opt/gopath/src/github.com/hyperledger/fabric/peer \
hyperledger/fabric-peer:x86_64-1.1.0 peer node start






# wait for Hyperledger Fabric to start
# incase of errors when running later commands, issue export FABRIC_START_TIMEOUT=<larger number>
echo "sleeping for ${FABRIC_START_TIMEOUT} seconds to wait for fabric to complete start up"
sleep ${FABRIC_START_TIMEOUT}

# Create the channel
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@${DOMAIN_ORG1}/msp" \
peer0.${DOMAIN_ORG1} peer channel create -o ${DOMAIN_ORDERER}:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/channel.tx

# Join peer0.${DOMAIN_ORG1} to the channel.
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@${DOMAIN_ORG1}/msp" \
peer0.${DOMAIN_ORG1} peer channel join -b ${CHANNEL_NAME}.block

# Update the channel definition to define the anchor peer for Org1 as peer0.${DOMAIN_ORG1}
docker exec -e "CORE_PEER_MSPCONFIGPATH=/etc/hyperledger/msp/users/Admin@${DOMAIN_ORG1}/msp" \
peer0.${DOMAIN_ORG1} peer channel update -o ${DOMAIN_ORDERER}:7050 -c $CHANNEL_NAME -f /etc/hyperledger/configtx/${CONFIGTX_ORGANISATION1_NAME}anchors.tx 
