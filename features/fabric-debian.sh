#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/docs/hyperledger-fabric-feature.md
# Syntax: ./fabric-debian.sh [version]

ENABLE_NONROOT=${1:-"true"}
USERNAME=${2:-"automatic"}
HLF_VERSION=${3:-"latest"}

# TODO non-root?
echo "FAB ${HLF_VERSION}"

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su, or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi

ARCHITECTURE="$(uname -m)"
case ${ARCHITECTURE} in
    x86_64) ARCHITECTURE="amd64";;
    *) echo -e "Architecture ${architecture} unsupported"; exit 1 ;;
esac

# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in ${POSSIBLE_USERS[@]}; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi

# Determine the appropriate Fabric version
if [ "${HLF_VERSION}" = "latest" ]; then
    HLF_VERSION=2.4.6
elif [ "${HLF_VERSION}" = "lts" ]; then
    HLF_VERSION=2.2.8
elif [ "${HLF_VERSION:0:4}" != "2.2" ] && [ "${HLF_VERSION:0:4}" != "2.3" ] && [ "${HLF_VERSION:0:4}" != "2.4" ]; then
    echo -e "Unsupported Fabric version ${HLF_VERSION}: only 2.2.x, 2.3.x, or 2.4.x versions are supported"
    exit 1
fi

# Function to run apt-get if needed
apt_get_update_if_needed()
{
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update
    else
        echo "Skipping apt-get update."
    fi
}

# Checks if packages are installed and installs them if not
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update_if_needed
        apt-get -y install --no-install-recommends "$@"
    fi
}

export DEBIAN_FRONTEND=noninteractive

# Install required packages if missing (TBC!)
check_packages curl ca-certificates apt-transport-https dirmngr gnupg2 findutils gcc git gzip make python3 tar unzip
if ! type git > /dev/null 2>&1; then
    apt_get_update_if_needed
    apt-get -y install --no-install-recommends git
fi

# Install couchdb
# curl https://couchdb.apache.org/repo/keys.asc | gpg --dearmor | tee /usr/share/keyrings/couchdb-archive-keyring.gpg >/dev/null 2>&1
# source /etc/os-release
# echo "deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couchdb-deb/ ${VERSION_CODENAME} main" \
#     | tee /etc/apt/sources.list.d/couchdb.list >/dev/null
# apt_get_update_if_needed
# apt-get -y install couchdb

# Install yq
curl -sSLo /usr/local/bin/yq https://github.com/mikefarah/yq/releases/download/v4.23.1/yq_linux_${ARCHITECTURE} && chmod +x /usr/local/bin/yq

# Download Fabric install script
mkdir -p /tmp/hyperledger/fabric
curl -sSLo /tmp/hyperledger/fabric/install-fabric.sh https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x /tmp/hyperledger/fabric/install-fabric.sh

# Install Fabric binaries and config
pushd /tmp/hyperledger/fabric
./install-fabric.sh --fabric-version ${HLF_VERSION} binary
mkdir -p /opt/hyperledger/fabric
if [ -d ./builders/ccaas ]; then
    mv ./builders /opt/hyperledger/fabric
fi
mkdir -p /usr/local/bin
if [ -d ./bin/ccaas_builder ]; then
    rm -Rf ./bin/ccaas_builder
fi
mv ./bin/* /usr/local/bin
FABRIC_CFG_PATH=/etc/hyperledger/fabric/config
mkdir -p ${FABRIC_CFG_PATH}
mv ./config/* ${FABRIC_CFG_PATH}
popd

# Install Fabric samples
if [ "${USERNAME}" = "root" ]; then
    FABRIC_SAMPLES_PARENT=/usr/local/src/github.com/hyperledger
else
    FABRIC_SAMPLES_PARENT=/home/${USERNAME}
fi
mkdir -p ${FABRIC_SAMPLES_PARENT}
pushd ${FABRIC_SAMPLES_PARENT}
/tmp/hyperledger/fabric/install-fabric.sh --fabric-version ${HLF_VERSION} samples
ln -s /usr/local/bin ./fabric-samples/bin && ln -s /etc/hyperledger/fabric/config ./fabric-samples/config
popd

# Clean up Fabric install script
rm -Rf /tmp/hyperledger/fabric

# Configure ccaas builder
yq e 'del(.vm.endpoint) | (.chaincode.externalBuilders[] | select(.name == "ccaas_builder") | .path) = "/opt/hyperledger/fabric/builders/ccaas"' -i ${FABRIC_CFG_PATH}/core.yaml

# Install microfab
curl --fail --silent --show-error -L "https://github.com/IBM-Blockchain/microfab/releases/download/v0.0.16/microfab-Linux-X64.tgz" -o "/tmp/microfab-Linux-X64.tgz"
tar -C /usr/local/bin -xzf "/tmp/microfab-Linux-X64.tgz" microfabd
rm "/tmp/microfab-Linux-X64.tgz"
mkdir -p "/opt/hyperledger/microfab/builders"
if [ -d /opt/hyperledger/fabric/builders/ccaas ]; then
    ln -s /opt/hyperledger/fabric/builders/ccaas /opt/hyperledger/microfab/builders/ccaas
fi
groupadd microfab
mkdir -p "/var/opt/hyperledger/microfab"
chown root:microfab /var/opt/hyperledger/microfab

if [ "${USERNAME}" != "root" ]; then
    chown -R ${USERNAME}:${USERNAME} /home/${USERNAME}
    adduser ${USERNAME} microfab
fi
