#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause 
#
source "scripts/textutils.sh"

clear
printMsg ""
printMsg "The features and functionality included in this reference design"
printMsg "are intended to showcase the capabilities of the Intel® RSP by"
printMsg "demonstrating the use of the API to collect and process RFID tag"
printMsg "read information. THIS SOFTWARE IS NOT INTENDED TO BE A COMPLETE"
printMsg "END-TO-END INVENTORY MANAGEMENT SOLUTION."
printMsg
printMsg "This script will download and install the Intel® RSP SW Toolkit-"
printMsg "Controller dockerized Java application along with its dependencies."
printMsg "This script is designed to run on Debian 10 or Ubuntu 18.04 LTS."
printMsg ""

printMsg "Checking Internet connectivity"
echo

PING1=$(ping -c 1 8.8.8.8)
if [[ $PING1 == *"unreachable"* ]]; then
    printDatedErrMsg "ERROR: No network connection found, exiting."
    exit 1
elif [[ $PING1 == *"100% packet loss"* ]]; then
    printDatedErrMsg "ERROR: No Internet connection found, exiting."
    exit 1
fi

PING2=$(ping -c 1 pool.ntp.org)
    if [[ $PING2 == *"not known"* ]]; then
        printDatedErrMsg "ERROR: Cannot resolve pool.ntp.org."
        printDatedInfoMsg "Is your network blocking IGMP ping?"
        printDatedErrMsg "exiting"
        exit 1
    else
        printDatedOkMsg "Connectivity OK"
    fi

echo
printDatedMsg "Updating apt..."
sudo apt update

printDatedMsg "Installing the following dependencies..."
printDatedMsg "    docker bash curl ntpdate"
echo
sudo apt -y install docker.io bash curl ntpdate

printDatedMsg "Checking for docker-compose..."
which docker-compose
if [ $? -ne 0 ]; then
    printDatedInfoMsg "docker-compose not found, installing..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod a+x /usr/local/bin/docker-compose
    if [ $? -ne 0 ]; then
        printDatedOkMsg "Installed docker-compose"
        docker-compose --version
    else
        printDatedErrMsg "Problem installing docker-compose"
        exit 1
    fi
else
    printDatedOkMsg "docker-compose found"
    docker-compose --version
fi


systemctl enable docker

echo
PROJECTS_DIR=$HOME/projects
if [ ! -d "$PROJECTS_DIR" ]; then
    printDatedMsg "Creating the projects directory..."
    mkdir $PROJECTS_DIR
fi
cd $PROJECTS_DIR

echo
GIT_VERSION=$(git --version)
if [[ $GIT_VERSION == *"git version"* ]]; then
    printDatedMsg "Cloning the RSP SW Toolkit - Installer..."
else
    printDatedErrMsg "git did not install properly, exiting."
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

if [ "${HTTP_PROXY+x}" != "" ]; then
	export DOCKER_BUILD_ARGS="--build-arg http_proxy='${http_proxy}' --build-arg https_proxy='${https_proxy}' --build-arg HTTP_PROXY='${HTTP_PROXY}' --build-arg HTTPS_PROXY='${HTTPS_PROXY}' --build-arg NO_PROXY='localhost,127.0.0.1'"
	export DOCKER_RUN_ARGS="--env http_proxy='${http_proxy}' --env https_proxy='${https_proxy}' --env HTTP_PROXY='${HTTP_PROXY}' --env HTTPS_PROXY='${HTTPS_PROXY}' --env NO_PROXY='localhost,127.0.0.1'"
	export AWS_CLI_PROXY="export http_proxy='${http_proxy}'; export https_proxy='${https_proxy}'; export HTTP_PROXY='${HTTP_PROXY}'; export HTTPS_PROXY='${HTTPS_PROXY}'; export NO_PROXY='localhost,127.0.0.1';"
else
	export DOCKER_BUILD_ARGS=""
	export DOCKER_RUN_ARGS=""
	export AWS_CLI_PROXY=""
fi

# Build RSP Controller
msg="Building the containers, this can take a few minutes..."
printBanner $msg
logMsg $msg
source "scripts/buildRspGw.sh"

msg="Run 'docker-compose -f docker-compose.yml up' to start"
printBanner $msg
docker-compose -p rsp -f $PROJECTS_DIR/rsp-sw-toolkit-installer/docker/compose/docker-compose.yml up -d
