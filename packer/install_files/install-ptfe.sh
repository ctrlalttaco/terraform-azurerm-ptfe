#!/usr/bin/env bash

# Supported Operating Systems
# 1. Ubuntu 18.04 LTS

set -e

readonly DEBIAN_FRONTEND="noninteractive"
readonly INSTALLER_DIR="/opt/tfe-installer"
readonly REPLICATED_URL="${REPLICATED_URL:-unset}"
readonly TFE_URL="${TFE_URL:-unset}"
readonly LICENSE_URL="${LICENSE_URL:-unset}"

export DEBIAN_FRONTEND

# Create installation source directory
mkdir -p $INSTALLER_DIR
cd $INSTALLER_DIR

# Download the Replicated installer and TFE airgap packages
echo "Downloading TFE license file..."
curl -fSL -o tfe-license.rli $LICENSE_URL
echo "Downloading TFE airgap package..."
curl -fSL -o tfe-airgap.tar.gz $TFE_URL
echo "Downloading Replicated installer package..."
curl -fSL -o replicated.tar.gz $REPLICATED_URL

# Extract the Replicated installer package
tar -zxvf replicated.tar.gz
rm -f replicated.tar.gz

# Install supported version of Docker CE
./install.sh no-proxy install-docker-only

# Prevent Docker CE version from being updated to an unsupported version
apt-mark hold docker-ce

# Install PostgreSQL client to configure schema
# curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
# add-apt-repository \
#    "deb [arch=amd64] http://apt.postgresql.org/pub/repos/apt \
#    $(lsb_release -cs)-pgdg \
#    main"
# apt-get -y install postgresql-client-10

