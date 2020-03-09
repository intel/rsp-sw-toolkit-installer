#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#

C_RED='\e[31m'
C_GREEN='\e[32m'
C_BLUE='\e[34m'
C_YELLOW='\e[33m'

T_RESET='\e[0m'
T_BOLD='\e[1m'

T_ERR="${T_BOLD}\e[31;1m"
T_ERR_ICON="[${T_BOLD}${C_RED}✗${T_RESET}]"

T_OK_ICON="[${T_BOLD}${C_GREEN}✓${T_RESET}]"
T_INFO_ICON="[${T_BOLD}${C_YELLOW}i${T_RESET}]"

printMsg() { echo -e "${1}" 2>&1; }

printDatedMsg() {
    printMsg "${C_BLUE}$(date +"%Y-%m-%d %I:%M:%S")${T_RESET} - ${1}${T_RESET}"
}

printDatedInfoMsg() {
    printMsg "${C_BLUE}$(date +"%Y-%m-%d %I:%M:%S")${T_RESET} - ${T_INFO_ICON} ${1}${T_RESET}"
}

printDatedErrMsg() {
    printMsg "${C_BLUE}$(date +"%Y-%m-%d %I:%M:%S")${T_RESET} - ${T_ERR_ICON}${T_ERR} $1${T_RESET}"
}

printDatedOkMsg() {
    printMsg "${C_BLUE}$(date +"%Y-%m-%d %I:%M:%S")${T_RESET} - ${T_OK_ICON} $1${T_RESET}"
}

clear
printMsg ""
printMsg "The features and functionality included in this reference design"
printMsg "are intended to showcase the capabilities of the Intel® RSP by"
printMsg "demonstrating the use of the API to collect and process RFID tag"
printMsg "read information. THIS SOFTWARE IS NOT INTENDED TO BE A COMPLETE"
printMsg "END-TO-END INVENTORY MANAGEMENT SOLUTION."
printMsg ""
printMsg "This script will download and install the Intel® RSP SW Toolkit-"
printMsg "Controller monolithic Java application along with its dependencies."
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
printDatedMsg "    tar openjdk git gradle"
printDatedMsg "    mosquitto mosquitto-clients"
printDatedMsg "    avahi-daemon ntp ssh wget"
sudo apt -y install tar default-jdk git gradle \
    mosquitto mosquitto-clients \
    avahi-daemon ntp ntp-doc ssh wget
if [ $? -ne 0 ]; then
    printDatedErrMsg "There was a problem installing dependencies, exiting"
    exit 1
fi

PROJECTS_DIR="$HOME/projects"
DEPLOY_DIR="$HOME/deploy"

if [ ! -d "$PROJECTS_DIR" ]; then
    printDatedMsg "Creating the projects directory..."
    mkdir "$PROJECTS_DIR"
fi
cd "$PROJECTS_DIR" || {
    printDatedErrMsg "Can't find the projects directory"
    exit 1
}

echo
GIT_VERSION="$(git --version)"
if [[ $GIT_VERSION == *"git version"* ]]; then
    printDatedMsg "Cloning the RSP SW Toolkit - Controller..."
else
    printDatedErrMsg "git did not install properly, exiting."
    exit 1
fi
if [ ! -d "$PROJECTS_DIR/rsp-sw-toolkit-gw" ]; then
    cd "$PROJECTS_DIR" || {
        printDatedErrMsg "Can't find the projects directory"
        exit 1
    }
    git clone https://github.com/intel/rsp-sw-toolkit-gw.git
fi
cd "$PROJECTS_DIR/rsp-sw-toolkit-gw" || {
    printDatedErrMsg "Can't find the projects toolkit directory"
    exit 1
}
git pull

echo
GRADLE_VERSION="$(gradle --version)"
if [[ $GRADLE_VERSION == *"Revision"* ]]; then
    printDatedMsg "Deploying the RSP SW Toolkit - Controller..."
else
    printDatedErrMsg "gradle did not install properly, exiting."
    exit 1
fi
gradle clean deploy

JAVA_HOME="$(type -p java)"
if [[ $JAVA_HOME == *"java"* ]]; then
    echo
else
    printDatedErrMsg "java did not install properly, exiting."
    exit 1
fi
RUN_DIR="$DEPLOY_DIR/rsp-sw-toolkit-gw"

if [ ! -d "$RUN_DIR/cache" ]; then
    printDatedMsg "Creating cache directory..."
    mkdir "$RUN_DIR/cache"
    printDatedMsg "Generating certificates..."
    cd "$RUN_DIR/cache" && ../gen_keys.sh
fi
echo
if [ ! -f "$RUN_DIR/cache/keystore.p12" ]; then
    printDatedErrMsg "Certificate creation failed, exiting."
    exit 1
fi

if [ ! -d "$RUN_DIR/sensor-sw-repo" ]; then
    printDatedMsg "Creating sensor-sw-repo directory..."
    mkdir "$RUN_DIR/sensor-sw-repo"
fi

printDatedMsg "Configuring NTP Server to serve time with no Internet ..."
NTP_FILE="/etc/ntp.conf"
TMP_FILE="/tmp/ntp.conf"
NTP_STRING1="server 127.127.1.0 prefer"
NTP_STRING2="fudge 127.127.22.1"
END_OF_FILE=$(tail -n 3 "$NTP_FILE")
if [[ $END_OF_FILE == *"$NTP_STRING1"* ]]; then
    printDatedOkMsg "Already Configured"
else
    printDatedMsg "Updating $NTP_FILE"
    cp "$NTP_FILE" "$TMP_FILE"
    echo >>"$TMP_FILE"
    printDatedInfoMsg "# If you want to serve time locally with no Internet," >>"$TMP_FILE"
    printDatedInfoMsg "# uncomment the next two lines" >>"$TMP_FILE"
    echo "$NTP_STRING1" >>"$TMP_FILE"
    echo "$NTP_STRING2" >>"$TMP_FILE"
    echo >>"$TMP_FILE"
    sudo cp "$TMP_FILE" "$NTP_FILE"
    sudo /etc/init.d/ntp restart
fi

echo
cd "$PROJECTS_DIR/rsp-sw-toolkit-installer/native" || {
    printDatedErrMsg "Can't find the native directory"
    exit 1
}
if [ ! -f "$PROJECTS_DIR/rsp-sw-toolkit-installer/native/open-web-admin.sh" ]; then
    printDatedInfoMsg "WARNING: The script open-web-admin.sh was not found."
else
    "$PROJECTS_DIR/rsp-sw-toolkit-installer/native/open-web-admin.sh" &
fi
printDatedMsg "Running the RSP SW Toolkit - Controller..."
cd "$RUN_DIR" || {
    printDatedErrMsg "Can't find the run directory"
    exit 1
}
"$RUN_DIR/run.sh"
