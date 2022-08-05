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

# TODO Install couch?!
# sudo apt update && sudo apt install -y curl apt-transport-https gnupg
# curl https://couchdb.apache.org/repo/keys.asc | gpg --dearmor | sudo tee /usr/share/keyrings/couchdb-archive-keyring.gpg >/dev/null 2>&1
# source /etc/os-release
# echo "deb [signed-by=/usr/share/keyrings/couchdb-archive-keyring.gpg] https://apache.jfrog.io/artifactory/couchdb-deb/ ${VERSION_CODENAME} main" \
#     | sudo tee /etc/apt/sources.list.d/couchdb.list >/dev/null

# Install required packages if missing (TBC!)
check_packages curl ca-certificates apt-transport-https dirmngr gnupg2 findutils gcc gcc-c++ git gzip make python3 tar unzip xz
if ! type git > /dev/null 2>&1; then
    apt_get_update_if_needed
    apt-get -y install --no-install-recommends git
fi

# TODO Install Fabric
mkdir -p /tmp/fabric
pushd /tmp/fabric
curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh
/tmp/fabric/install-fabric.sh --fabric-version ${HLF_VERSION} binary
mv ./bin/ccaas_builder ~/ccaas_builder
mkdir -p /usr/local/bin
mv ./bin/* /usr/local/bin
mkdir -p /etc/hyperledger/fabric
mv ./config /etc/hyperledger/fabric
popd

mkdir -p /usr/src/hyperledger
pushd /usr/src/hyperledger
/tmp/fabric/install-fabric.sh --fabric-version ${HLF_VERSION} samples
ln -s /usr/local/bin ./fabric-samples/bin && ln -s /etc/hyperledger/fabric/config ./fabric-samples/config
popd

rm -Rf /tmp/fabric

# TODO install microfab?!
#     && mkdir -p /opt/microfab/bin /opt/microfab/data \
#     && chgrp -R root /opt/microfab/data \
#     && chmod -R g=u /opt/microfab/data \
#     && go build -o /opt/microfab/bin/microfabd cmd/microfabd/main.go \
#     && cp -rf builders /opt/microfab/builders

# TODO install ccaas builder
