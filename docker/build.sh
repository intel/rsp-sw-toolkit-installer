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
printMsg ""
printMsg "This script will download and install the Intel® RSP SW Toolkit-"
printMsg "Controller dockerized Java application along with its dependencies."
printMsg "This script is designed to run on Debian 10 or Ubuntu 18.04 LTS."
printMsg ""

printDatedMsg "Checking Internet connectivity"
PING1="$(ping -c 1 8.8.8.8)"

if [[ $PING1 == *"unreachable"* ]]; then
    printDatedErrMsg "ERROR: No network connection found, exiting."
    exit 1
elif [[ $PING1 == *"100% packet loss"* ]]; then
    printDatedErrMsg "ERROR: No Internet connection found, exiting."
    exit 1
fi

PING2="$(ping -c 1 pool.ntp.org)"
if [[ $PING2 == *"not known"* ]]; then
    printDatedErrMsg "ERROR: Cannot resolve pool.ntp.org."
    printDatedInfoMsg "INFO: Is your network blocking IGMP ping?"
    printDatedErrMsg "ERROR: exiting"
    exit 1
else
    printDatedOkMsg "Connectivity OK"
fi

echo
printDatedMsg "Updating apt..."
sudo apt update >>/dev/null 2>&1

printDatedMsg "Checking for docker..."
command -v docker
if [ $? -ne 0 ]; then
    printDatedInfoMsg "INFO: docker not found, installing..."
    sudo apt -y install docker.io
    if [ $? -ne 0 ]; then
        printDatedErrMsg "ERROR: Problem installing docker"
        exit 1
    else
        printDatedOkMsg "OK: Installed docker"
        docker --version
    fi
else
    printDatedOkMsg "OK: found docker"
    docker --version
fi

printDatedMsg "Installing the following dependencies..."
printDatedMsg "    curl ntpdate git"
echo
sudo apt -y install curl ntpdate git
if [ $? -ne 0 ]; then
    printDatedErrMsg "ERROR: There was a problem installing dependencies, exiting"
    exit 1
fi

printDatedMsg "Checking for docker-compose..."
command -v docker-compose
if [ $? -ne 0 ]; then
    printDatedInfoMsg "INFO: docker-compose not found, installing..."
    sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && sudo chmod a+x /usr/local/bin/docker-compose
    if [ $? -ne 0 ]; then
        printDatedErrMsg "ERROR: Problem installing docker-compose"
        exit 1
    else
        printDatedOkMsg "OK: Installed docker-compose"
        docker-compose --version
    fi
else
    printDatedOkMsg "OK: found docker-compose"
    docker-compose --version
fi

PROJECTS_DIR=$HOME/projects
if [ ! -d "$PROJECTS_DIR" ]; then
    printDatedMsg "Creating the projects directory..."
    mkdir "$PROJECTS_DIR"
fi

echo
GIT_VERSION="$(git --version)"
if [[ $GIT_VERSION == *"git version"* ]]; then
    printDatedOkMsg "OK: Found git..."
else
    printDatedErrMsg "ERROR: git not found, exiting."
    exit 1
fi

#clone the installer
if [ ! -d "$PROJECTS_DIR/rsp-sw-toolkit-installer" ]; then
    cd "$PROJECTS_DIR" || {
        printDatedErrMsg "ERROR: Can't find the projects directory"
        exit 1
    }
    printDatedMsg "Going to clone the RSP SW Toolkit - Installer..."
    git clone https://github.com/intel/rsp-sw-toolkit-installer.git
fi

# clone the controller
if [ ! -d "$PROJECTS_DIR/rsp-sw-toolkit-gw" ]; then
    cd "$PROJECTS_DIR" || {
        printDatedErrMsg "ERROR: Can't find the projects directory"
        exit 1
    }
    printDatedMsg "Going to clone the RSP SW Toolkit - Controller..."
    git clone https://github.com/intel/rsp-sw-toolkit-gw.git
fi

# we want to have some checks done for undefined variables
set -u

cd "$PROJECTS_DIR"/rsp-sw-toolkit-installer/docker/ || {
    printDatedErrMsg "ERROR: Can't find the installer docker directory"
    exit 1
}

if [ "${HTTP_PROXY+x}" != "" ]; then
    export DOCKER_BUILD_ARGS="--build-arg http_proxy='${HTTP_PROXY}' --build-arg https_proxy='${HTTPS_PROXY}' --build-arg HTTP_PROXY='${HTTP_PROXY}' --build-arg HTTPS_PROXY='${HTTPS_PROXY}' --build-arg NO_PROXY='localhost,127.0.0.1'"
    export DOCKER_RUN_ARGS="--env http_proxy='${HTTP_PROXY}' --env https_proxy='${HTTPS_PROXY}' --env HTTP_PROXY='${HTTP_PROXY}' --env HTTPS_PROXY='${HTTPS_PROXY}' --env NO_PROXY='localhost,127.0.0.1'"
    export AWS_CLI_PROXY="export http_proxy='${HTTP_PROXY}'; export https_proxy='${HTTPS_PROXY}'; export HTTP_PROXY='${HTTP_PROXY}'; export HTTPS_PROXY='${HTTPS_PROXY}'; export NO_PROXY='localhost,127.0.0.1';"
else
    export DOCKER_BUILD_ARGS=""
    export DOCKER_RUN_ARGS=""
    export AWS_CLI_PROXY=""
fi

# Build RSP Controller
msg="Building the containers, this can take a few minutes..."
printBanner "$msg"
logMsg "$msg"
source scripts/buildRspGw.sh

msg="Bringing up RSP using docker-compose"
printBanner "$msg"
sudo docker-compose -p rsp -f "$PROJECTS_DIR"/rsp-sw-toolkit-installer/docker/compose/docker-compose.yml up -d
