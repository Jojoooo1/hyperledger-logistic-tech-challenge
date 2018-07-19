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

DOMAIN_ORG=(intelipost.shipper.logistic.com carriers.transporter.logistic.com correios.transporter.logistic.com)
# PEER_DOMAIN_ORG=((peer0.intelipost.shipper.logistic.com), (pper0.carriers.transporter.logistic.com), (correios.transporter.logistic.com))
NAME_ORG=(intelipost carriers correios)

DOMAIN_ORDERER=intelipost.orderer.logistic.com
DOMAIN_ORDERER_WO_HOST=orderer.logistic.com

CONFIGTX_ORGANISATION_ID=(IntelipostShipperMSP CarriersMSP CorreiosMSP)

CHANNEL_NAME=channel
NETWORK_NAME=logistic-network
COMPOSER_BNA_NAME=logistic-network@0.0.1.bna
BNA_VERSION=0.0.1
DIR=$PWD
HOST_IP=(192.168.1.31 192.168.1.34 192.168.1.33) # (hostOrg1 hostOrg2)

generateFolderToBeSendAfterBuild() {
if [ -d tmp ]; then
    rm -rf tmp
fi
if [ -d card ]; then
    rm -rf card
fi
if [ -d ../toSendAfterIdentityCreation ]; then
    rm -rf ../toSendAfterIdentityCreation
fi
for i in ${!NAME_ORG[@]} 
do
mkdir -p tmp/${NAME_ORG[$i]}
done
mkdir -p tmp/card && mkdir -p ../toSendAfterIdentityCreation 
}
generateFolderToBeSendAfterBuild

#copy TLS CA cert
# awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' composer/crypto-config/peerOrganizations/${DOMAIN_ORG[0]}/peers/peer0.${DOMAIN_ORG[0]}/tls/ca.crt > $(pwd)/tmp/org1/ca-org1.txt
# awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' composer/crypto-config/peerOrganizations/${DOMAIN_ORG[1]}/peers/peer0.${DOMAIN_ORG[1]}/tls/ca.crt > $(pwd)/tmp/org2/ca-org2.txt
# awk 'NF {sub(/\r/, ""); printf "%s\\n",$0;}' composer/crypto-config/ordererOrganizations/${DOMAIN_ORDERER_WO_HOST}/orderers/${DOMAIN_ORDERER}/tls/ca.crt > $(pwd)/tmp/ca-orderer.txt

for i in ${!DOMAIN_ORG[@]} 
do

cat << EOF > $(pwd)/tmp/${NAME_ORG[$i]}/${NETWORK_NAME}-${NAME_ORG[$i]}.json
{
    "name": "${NETWORK_NAME}",
    "x-type": "hlfv1",
    "version": "1.0.0",
    "client": {
        "organization": "${NAME_ORG[$i]^}",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "${CHANNEL_NAME}": {
            "orderers": [
            "${DOMAIN_ORDERER}"
            ],
            "peers": {
                "peer0.${DOMAIN_ORG[0]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                },
                "peer0.${DOMAIN_ORG[1]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                },
                "peer0.${DOMAIN_ORG[2]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                }
            }
        }
    },
    "organizations": {
        "${NAME_ORG[0]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[O]}",
            "peers": [
            "peer0.${DOMAIN_ORG[0]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[0]}"
            ]
        },
        "${NAME_ORG[1]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[1]}",
            "peers": [
            "peer0.${DOMAIN_ORG[1]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[1]}"
            ]
        },
        "${NAME_ORG[2]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[2]}",
            "peers": [
            "peer0.${DOMAIN_ORG[2]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[2]}"
            ]
        }
    },
    "orderers": {
        "${DOMAIN_ORDERER}": {
            "url": "grpc://localhost:7050"
        }
    },
    "peers": {
        "peer0.${DOMAIN_ORG[0]}": {
            "url": "grpc://localhost:7051",
            "eventUrl": "grpc://localhost:7053"
        },
        "peer0.${DOMAIN_ORG[1]}": {
            "url": "grpc://${HOST_IP[1]}:8051",
            "eventUrl": "grpc://${HOST_IP[1]}:8053"
        },
        "peer0.${DOMAIN_ORG[2]}": {
            "url": "grpc://${HOST_IP[2]}:8051",
            "eventUrl": "grpc://${HOST_IP[2]}:8053"
        }
    },
    "certificateAuthorities": {
        "ca.${DOMAIN_ORG[0]}": {
            "url": "http://localhost:7054",
            "caName": "ca.${DOMAIN_ORG[0]}",
            "httpOptions": {
                "verify": false
            }
        },
        "ca.${DOMAIN_ORG[1]}": {
            "url": "http://${HOST_IP[1]}:8054",
            "caName": "ca.${DOMAIN_ORG[1]}",
            "httpOptions": {
                "verify": false
            }
        },
        "ca.${DOMAIN_ORG[2]}": {
            "url": "http://${HOST_IP[2]}:8054",
            "caName": "ca.${DOMAIN_ORG[2]}",
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF
done

cat << EOF > $(pwd)/tmp/endorsement-policy.json
{
    "identities": [
    {
        "role": {
            "name": "member",
            "mspId": "${CONFIGTX_ORGANISATION_ID[O]}"
        }
    },
    {
        "role": {
            "name": "member",
            "mspId": "${CONFIGTX_ORGANISATION_ID[1]}"
        }
    },
    {
        "role": {
            "name": "member",
            "mspId": "${CONFIGTX_ORGANISATION_ID[2]}"
        }
    }
    ],
    "policy": {
        "3-of": [
        {
            "signed-by": 0
        },
        {
            "signed-by": 1
        },
        {
            "signed-by": 2
        }
        ]
    }
}

EOF

# Remove previous network card
rm -rf ~/.composer/cards/*${NETWORK_NAME}*

# copy the signed cert and private key in tmp folder for creating fabric network card
for i in ${!NAME_ORG[@]}
do
msp_path=composer/crypto-config/peerOrganizations/${DOMAIN_ORG[$i]}/users/Admin@${DOMAIN_ORG[$i]}/msp
cp -p ${msp_path}/signcerts/A*.pem $(pwd)/tmp/${NAME_ORG[$i]} 
cp -p ${msp_path}/keystore/*_sk $(pwd)/tmp/${NAME_ORG[$i]}

composer card create -p $(pwd)/tmp/${NAME_ORG[$i]}/${NETWORK_NAME}-${NAME_ORG[$i]}.json \
-u PeerAdmin -c $(pwd)/tmp/${NAME_ORG[$i]}/Admin@${DOMAIN_ORG[$i]}-cert.pem -k  $(pwd)/tmp/${NAME_ORG[$i]}/*_sk \
-r PeerAdmin \
-r ChannelAdmin \
-f tmp/${NAME_ORG[$i]}/PeerAdmin@${NETWORK_NAME}-${NAME_ORG[$i]}.card

composer card import \
-f tmp/${NAME_ORG[$i]}/PeerAdmin@${NETWORK_NAME}-${NAME_ORG[$i]}.card \
--card PeerAdmin@${NETWORK_NAME}-${NAME_ORG[$i]}

cd ../../composer-logistic-network
composer network install --card PeerAdmin@${NETWORK_NAME}-${NAME_ORG[$i]} --archiveFile $COMPOSER_BNA_NAME
cd $DIR
composer identity request -c PeerAdmin@${NETWORK_NAME}-${NAME_ORG[$i]} -u admin -s adminpw -d admin${NAME_ORG[$i]^}
done


# # Create card for admin Org1 & org2:
# composer card create -p $(pwd)/tmp/org1/${NETWORK_NAME}-org1.json -u PeerAdmin -c  $(pwd)/tmp/org1/Admin@${DOMAIN_ORG[0]}-cert.pem -k  $(pwd)/tmp/org1/*_sk -r PeerAdmin -r ChannelAdmin -f tmp/org1/PeerAdmin@${NETWORK_NAME}-org1.card
# composer card create -p $(pwd)/tmp/org2/${NETWORK_NAME}-org2-provisory.json -u PeerAdmin -c  $(pwd)/tmp/org2/Admin@${DOMAIN_ORG[1]}-cert.pem -k  $(pwd)/tmp/org2/*_sk -r PeerAdmin -r ChannelAdmin -f tmp/org2/PeerAdmin@${NETWORK_NAME}-org2.card
# # Import card for Org1 & Org2:
# composer card import -f tmp/org1/PeerAdmin@${NETWORK_NAME}-org1.card --card PeerAdmin@${NETWORK_NAME}-org1
# composer card import -f tmp/org2/PeerAdmin@${NETWORK_NAME}-org2.card --card PeerAdmin@${NETWORK_NAME}-org2

# Install chaincode on host 1 & 2
# cd ../../composer-logistic-network
# composer network install --card PeerAdmin@${NETWORK_NAME}-org1 --archiveFile $COMPOSER_BNA_NAME
# composer network install --card PeerAdmin@${NETWORK_NAME}-org2 --archiveFile $COMPOSER_BNA_NAME
# cd $DIR

# Request an identity admin at CA1 & CA2 for creating composer network card
# composer identity request -c PeerAdmin@${NETWORK_NAME}-org1 -u admin -s adminpw -d adminOrg1
# composer identity request -c PeerAdmin@${NETWORK_NAME}-org2 -u admin -s adminpw -d adminOrg2

# This command creates ***TĤREE*** new card file that are ***REGISTERED*** as composer network ADMIN on INSTANTIATION
composer network start -c PeerAdmin@${NETWORK_NAME}-${NAME_ORG[0]} \
-n $NETWORK_NAME -V $BNA_VERSION -o endorsementPolicyFile=${DIR}/tmp/endorsement-policy.json \
-A admin${NAME_ORG[0]^} -C admin${NAME_ORG[0]^}/admin-pub.pem \
-A admin${NAME_ORG[1]^} -C admin${NAME_ORG[1]^}/admin-pub.pem \
-A admin${NAME_ORG[2]^} -C admin${NAME_ORG[2]^}/admin-pub.pem \

# Recreate and import card for adminOrg1 (oblige to re create composer bug) 
composer card create -p ${DIR}/tmp/${NAME_ORG[0]}/${NETWORK_NAME}-${NAME_ORG[0]}.json \
-u admin${NAME_ORG[0]^} -n $NETWORK_NAME \
-c admin${NAME_ORG[0]^}/admin-pub.pem -k admin${NAME_ORG[0]^}/admin-priv.pem && \
composer card import -f admin${NAME_ORG[0]^}@${NETWORK_NAME}.card

# composer card create -p ${DIR}/tmp/org2/${NETWORK_NAME}-org2-provisory.json -u adminOrg2 -n $NETWORK_NAME -c adminOrg2/admin-pub.pem -k adminOrg2/admin-priv.pem \
# && composer card import -f adminOrg2@${NETWORK_NAME}.card

# Create Card for Org2 need to be send then to Org2
cat << EOF > $(pwd)/tmp/card/${NETWORK_NAME}-${NAME_ORG[1]}.json
{
    "name": "${NETWORK_NAME}",
    "x-type": "hlfv1",
    "version": "1.0.0",
    "client": {
        "organization": "${NAME_ORG[1]^}",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "${CHANNEL_NAME}": {
            "orderers": [
            "${DOMAIN_ORDERER}"
            ],
            "peers": {
                "peer0.${DOMAIN_ORG[0]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                },
                "peer0.${DOMAIN_ORG[1]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                },
                "peer0.${DOMAIN_ORG[2]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                }
            }
        }
    },
    "organizations": {
        "${NAME_ORG[0]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[O]}",
            "peers": [
            "peer0.${DOMAIN_ORG[0]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[0]}"
            ]
        },
        "${NAME_ORG[1]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[1]}",
            "peers": [
            "peer0.${DOMAIN_ORG[1]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[1]}"
            ]
        },
        "${NAME_ORG[2]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[2]}",
            "peers": [
            "peer0.${DOMAIN_ORG[2]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[2]}"
            ]
        }
    },
    "orderers": {
        "${DOMAIN_ORDERER}": {
            "url": "grpc://${HOST_IP[0]}:7050"
        }
    },
    "peers": {
        "peer0.${DOMAIN_ORG[0]}": {
            "url": "grpc://${HOST_IP[0]}:7051",
            "eventUrl": "grpc://${HOST_IP[0]}:7053"
        },
        "peer0.${DOMAIN_ORG[1]}": {
            "url": "grpc://localhost:8051",
            "eventUrl": "grpc://localhost:8053"
        },
        "peer0.${DOMAIN_ORG[2]}": {
            "url": "grpc://${HOST_IP[2]}:8051",
            "eventUrl": "grpc://${HOST_IP[2]}:8053"
        }
    },
    "certificateAuthorities": {
        "ca.${DOMAIN_ORG[0]}": {
            "url": "http://${HOST_IP[0]}:7054",
            "caName": "ca.${DOMAIN_ORG[0]}",
            "httpOptions": {
                "verify": false
            }
        },
        "ca.${DOMAIN_ORG[1]}": {
            "url": "http://localhost:8054",
            "caName": "ca.${DOMAIN_ORG[1]}",
            "httpOptions": {
                "verify": false
            }
        },
        "ca.${DOMAIN_ORG[2]}": {
            "url": "http://${HOST_IP[2]}:8054",
            "caName": "ca.${DOMAIN_ORG[2]}",
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF

cat << EOF > $(pwd)/tmp/card/${NETWORK_NAME}-${NAME_ORG[2]}.json
{
    "name": "${NETWORK_NAME}",
    "x-type": "hlfv1",
    "version": "1.0.0",
    "client": {
        "organization": "${NAME_ORG[2]^}",
        "connection": {
            "timeout": {
                "peer": {
                    "endorser": "300",
                    "eventHub": "300",
                    "eventReg": "300"
                },
                "orderer": "300"
            }
        }
    },
    "channels": {
        "${CHANNEL_NAME}": {
            "orderers": [
            "${DOMAIN_ORDERER}"
            ],
            "peers": {
                "peer0.${DOMAIN_ORG[0]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                },
                "peer0.${DOMAIN_ORG[1]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                },
                "peer0.${DOMAIN_ORG[2]}": {
                    "endorsingPeer": true,
                    "chaincodeQuery": true,
                    "eventSource": true
                }
            }
        }
    },
    "organizations": {
        "${NAME_ORG[0]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[O]}",
            "peers": [
            "peer0.${DOMAIN_ORG[0]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[0]}"
            ]
        },
        "${NAME_ORG[1]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[1]}",
            "peers": [
            "peer0.${DOMAIN_ORG[1]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[1]}"
            ]
        },
        "${NAME_ORG[2]^}": {
            "mspid": "${CONFIGTX_ORGANISATION_ID[2]}",
            "peers": [
            "peer0.${DOMAIN_ORG[2]}"
            ],
            "certificateAuthorities": [
            "ca.${DOMAIN_ORG[2]}"
            ]
        }
    },
    "orderers": {
        "${DOMAIN_ORDERER}": {
            "url": "grpc://${HOST_IP[0]}:7050"
        }
    },
    "peers": {
        "peer0.${DOMAIN_ORG[0]}": {
            "url": "grpc://${HOST_IP[0]}:7051",
            "eventUrl": "grpc://${HOST_IP[0]}:7053"
        },
        "peer0.${DOMAIN_ORG[1]}": {
            "url": "grpc://${HOST_IP[1]}:8051",
            "eventUrl": "grpc://${HOST_IP[1]}:8053"
        },
        "peer0.${DOMAIN_ORG[2]}": {
            "url": "grpc://localhost:8051",
            "eventUrl": "grpc://localhost:8053"
        }
    },
    "certificateAuthorities": {
        "ca.${DOMAIN_ORG[0]}": {
            "url": "http://${HOST_IP[0]}:7054",
            "caName": "ca.${DOMAIN_ORG[0]}",
            "httpOptions": {
                "verify": false
            }
        },
        "ca.${DOMAIN_ORG[1]}": {
            "url": "http://${HOST_IP[1]}:8054",
            "caName": "ca.${DOMAIN_ORG[1]}",
            "httpOptions": {
                "verify": false
            }
        },
        "ca.${DOMAIN_ORG[2]}": {
            "url": "http://localhost:8054",
            "caName": "ca.${DOMAIN_ORG[2]}",
            "httpOptions": {
                "verify": false
            }
        }
    }
}
EOF

# Create card to send to Org 2 with adapted IP connection.json file
composer card create -p ${DIR}/tmp/card/${NETWORK_NAME}-${NAME_ORG[1]}.json \
-u admin${NAME_ORG[1]^} -n $NETWORK_NAME -c admin${NAME_ORG[1]^}/admin-pub.pem -k admin${NAME_ORG[1]^}/admin-priv.pem 

composer card create -p ${DIR}/tmp/card/${NETWORK_NAME}-${NAME_ORG[2]}.json \
-u admin${NAME_ORG[2]^} -n $NETWORK_NAME -c admin${NAME_ORG[2]^}/admin-pub.pem -k admin${NAME_ORG[2]^}/admin-priv.pem 

# Create folder containing the card to send
mv admin${NAME_ORG[1]^}@${NETWORK_NAME}.card $(pwd)/../toSendAfterIdentityCreation
mv admin${NAME_ORG[2]^}@${NETWORK_NAME}.card $(pwd)/../toSendAfterIdentityCreation

composer network ping -c admin${NAME_ORG[0]^}@${NETWORK_NAME}

# Remove card created, cause now stored in wallet
rm -rf admin* && rm -rf tmp 
