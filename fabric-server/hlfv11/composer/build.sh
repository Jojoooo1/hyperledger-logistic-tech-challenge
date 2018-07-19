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
CHANNEL_NAME=channel 
CONFIGTX_ORGANISATION_NAME=(IntelipostShipper Carriers Correios)
# list of other particpant
other_participants=(carriers.transporter.logistic.com correios.transporter.logistic.com)

function generateCert() {
  rm -Rf crypto-config
  set -x
  cryptogen generate --config=./crypto-config.yaml
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate certificates..."
    exit 1
  fi
}

function generateChannelArtifacts() {
  which configtxgen
  if [ "$?" -ne 0 ]; then
    echo "configtxgen tool not found. exiting"
    exit 1
  fi

  rm -Rf channel-artifacts/*

  set -x
  configtxgen -profile ThreeOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate orderer genesis block..."
    exit 1
  fi
  
  set -x
  configtxgen -profile ThreeOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
  res=$?
  set +x
  if [ $res -ne 0 ]; then
    echo "Failed to generate channel configuration transaction..."
    exit 1
  fi

  for i in ${!CONFIGTX_ORGANISATION_NAME[@]} 
  do
    set -x
    configtxgen -profile ThreeOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/${CONFIGTX_ORGANISATION_NAME[$i]}anchors.tx -channelID $CHANNEL_NAME -asOrg ${CONFIGTX_ORGANISATION_NAME[$i]}  
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate ${CONFIGTX_ORGANISATION_NAME[$i]} Anchor peer configuration transaction..."
      exit 1
    fi
  done

}

function generateFolderToBeSendAfterBuild() {
  if [ -d ../../toSendAfterBuild ]; then
    rm -rf ../../toSendAfterBuild
  fi
  mkdir -p ../../toSendAfterBuild

  for i in ${!other_participants[@]} 
  do
    set -x
    tar -czvf ../../toSendAfterBuild/${other_participants[$i]}.tar \
    ../initIdentityAndChainCode_$((i+2)).sh \
    ../startFabric_$((i+2)).sh \
    ../reset.sh \
    crypto-config/peerOrganizations/${other_participants[$i]} \
    channel-artifacts/${CONFIGTX_ORGANISATION_NAME[$((i+1))]}anchors.tx
    res=$?
    set +x
    if [ $res -ne 0 ]; then
      echo "Failed to generate tar file..."
      exit 1
    fi
  done
}

generateCert
generateChannelArtifacts
generateFolderToBeSendAfterBuild
