#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause 
#

clear
echo
echo "The features and functionality included in this reference design"
echo "are intended to showcase the capabilities of the Intel® RSP by"
echo "demonstrating the use of the API to collect and process RFID tag"
echo "read information. THIS SOFTWARE IS NOT INTENDED TO BE A COMPLETE"
echo "END-TO-END INVENTORY MANAGEMENT SOLUTION."
echo
echo "This script will download and install the Intel® RSP SW Toolkit-"
echo "Gateway dockerized Java application along with its dependencies."
echo "This script is designed to run on Debian 9 or Ubuntu 18.04 LTS."
echo 
#echo "This script will also download and install the latest software"
#echo "repository for Intel® RFID Sensor Platforms (H1000/H3000/H4000)."
#echo "By continuing with this installation, you agree to the terms in"
#echo "the End User License Agreemnt Intel-RSP-EULA-Agreement.pdf."
#echo "https://github.com/intel/rsp-sw-toolkit-installer/sensor-sw-repo"
#echo
#echo "IMPORTANT! PLEASE READ AND AGREE TO THIS EULA BEFORE CONTINUING!"
#echo 
#read -p 'Press [Enter] to continue... or [Ctrl]-[C] to exit...'
#echo
CURRENT_DIR=$(pwd)

echo "Checking Internet connectivity"
echo
PING1=$(ping -c 1 8.8.8.8)
PING2=$(ping -c 1 pool.ntp.org)
if [[ $PING1 == *"unreachable"* ]]; then
    echo "ERROR: No network connection found, exiting."
    exit 1
elif [[ $PING1 == *"100% packet loss"* ]]; then
    echo "ERROR: No Internet connection found, exiting."
    exit 1
else
    if [[ $PING2 == *"not known"* ]]; then
        echo "ERROR: Cannot resolve pool.ntp.org."
        echo "Is your network blocking IGMP ping?"
        echo "exiting"
        exit 1
    else
        echo "Connectivity OK"
    fi
fi

echo
echo "Installing the following dependencies..."
echo "    1. docker"
echo "    2. docker-compose"
echo "    3. bash"
echo "    4. curl"
echo "    5. ntpdate"
echo
apt update
apt -y install docker.io bash curl ntpdate
apt -y autoremove
curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod a+x /usr/local/bin/docker-compose

systemctl enable docker

echo
PROJECTS_DIR=$HOME/projects
if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Creating the projects directory..."
    mkdir $PROJECTS_DIR
fi
cd $PROJECTS_DIR

echo
GIT_VERSION=$(git --version)
if [[ $GIT_VERSION == *"git version"* ]]; then
    echo "Cloning the RSP SW Toolkit - Installer..."
else
    echo "git did not install properly, exiting."
    exit 1
fi
if [ ! -d "$PROJECTS_DIR/rsp-sw-toolkit-installer" ]; then
    cd $PROJECTS_DIR
    git clone https://github.com/intel/rsp-sw-toolkit-installer.git
fi
cd $PROJECTS_DIR/rsp-sw-toolkit-installer
git pull

# we want to have some checks done for undefined variables
set -u

cd $PROJECTS_DIR/rsp-sw-toolkit-installer/docker/
source "scripts/textutils.sh"

if [ "${HTTP_PROXY+x}" != "" ]; then
	export DOCKER_BUILD_ARGS="--build-arg http_proxy='${http_proxy}' --build-arg https_proxy='${https_proxy}' --build-arg HTTP_PROXY='${HTTP_PROXY}' --build-arg HTTPS_PROXY='${HTTPS_PROXY}' --build-arg NO_PROXY='localhost,127.0.0.1'"
	export DOCKER_RUN_ARGS="--env http_proxy='${http_proxy}' --env https_proxy='${https_proxy}' --env HTTP_PROXY='${HTTP_PROXY}' --env HTTPS_PROXY='${HTTPS_PROXY}' --env NO_PROXY='localhost,127.0.0.1'"
	export AWS_CLI_PROXY="export http_proxy='${http_proxy}'; export https_proxy='${https_proxy}'; export HTTP_PROXY='${HTTP_PROXY}'; export HTTPS_PROXY='${HTTPS_PROXY}'; export NO_PROXY='localhost,127.0.0.1';"
else
	export DOCKER_BUILD_ARGS=""
	export DOCKER_RUN_ARGS=""
	export AWS_CLI_PROXY=""
fi

# Build Managed Edge Accelerator
msg="Building the containers, this can take a few minutes..."
printBanner $msg
logMsg $msg
source "scripts/buildRspGw.sh"

msg="Run 'docker-compose -f docker-compose.yml up' to start"
printBanner $msg
docker-compose -p rsp -f $PROJECTS_DIR/rsp-sw-toolkit-installer/docker/compose/docker-compose.yml up -d
