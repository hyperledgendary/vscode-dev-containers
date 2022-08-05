#!/usr/bin/env bash
#
# SPDX-License-Identifier: Apache-2.0
#
# Docs: https://github.com/microsoft/vscode-dev-containers/blob/main/docs/hyperledger-fabric-feature.md
# Syntax: ./fabric-debian.sh [version]

ENABLE_NONROOT=${1:-"true"}
USERNAME=${2:-"automatic"}
HLF_VERSION=${3:-"latest"}

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

# Install curl, apt-transport-https, curl, gpg, or dirmngr, git if missing (TBC!)
check_packages curl ca-certificates apt-transport-https dirmngr gnupg2
if ! type git > /dev/null 2>&1; then
    apt_get_update_if_needed
    apt-get -y install --no-install-recommends git
fi

if [ "${USERNAME}" != "root" ]; then
    mkdir -p /home/${USERNAME}/hyperledger
    pushd /home/${USERNAME}/hyperledger
else
    mkdir -p /usr/src/hyperledger
    pushd /usr/src/hyperledger
fi

curl -sSLO https://raw.githubusercontent.com/hyperledger/fabric/main/scripts/install-fabric.sh && chmod +x install-fabric.sh
./install-fabric.sh # TODO versions!

popd

if [ "${USERNAME}" != "root" ]; then
    chown -R ${USERNAME} /home/${USERNAME}/hyperledger
fi
