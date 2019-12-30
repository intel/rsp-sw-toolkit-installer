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
echo "Gateway monolithic Java application along with its dependencies."
echo "This script is designed to run on Debian 9 or Ubuntu 18.04 LTS."
echo 
echo "This script will also download and install the latest software"
echo "repository for Intel® RFID Sensor Platforms (H1000/H3000)."
echo "By continuing with this installation, you agree to the terms in"
echo "the End User License Agreement Intel-RSP-EULA-Agreement.pdf."
echo "https://github.com/intel/rsp-sw-toolkit-installer/tree/master/sensor-sw-repo"
echo
echo "IMPORTANT! PLEASE READ AND AGREE TO THIS EULA BEFORE CONTINUING!"
echo 
read -p 'Press [Enter] to continue... or [Ctrl]-[C] to exit...'
echo
CURRENT_DIR="$(pwd)"

echo "Checking Internet connectivity"
echo
PING1="$(ping -c 1 8.8.8.8)"
PING2="$(ping -c 1 pool.ntp.org)"
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
echo "    1. tar"
echo "    2. openjdk"
echo "    3. git"
echo "    4. gradle"
echo "    5. mosquitto"
echo "    6. mosquitto-clients"
echo "    7. avahi-daemon"
echo "    8. ntp"
echo "    9. ssh"
echo
sudo apt update
sudo apt -y install tar default-jdk git gradle 
sudo apt -y install mosquitto mosquitto-clients avahi-daemon
sudo apt -y install ntp ntp-doc ssh wget
sudo apt -y autoremove

echo
PROJECTS_DIR="$HOME/projects"
DEPLOY_DIR="$HOME/deploy"

if [ ! -d "$PROJECTS_DIR" ]; then
    echo "Creating the projects directory..."
    mkdir "$PROJECTS_DIR"
fi
cd "$PROJECTS_DIR"

echo
GIT_VERSION="$(git --version)"
if [[ $GIT_VERSION == *"git version"* ]]; then
    echo "Cloning the RSP SW Toolkit - Gateway..."
else
    echo "git did not install properly, exiting."
    exit 1
fi
if [ ! -d "$PROJECTS_DIR/rsp-sw-toolkit-gw" ]; then
    cd "$PROJECTS_DIR"
    git clone https://github.com/intel/rsp-sw-toolkit-gw.git
fi
cd "$PROJECTS_DIR/rsp-sw-toolkit-gw"
git pull

echo
GRADLE_VERSION="$(gradle --version)"
if [[ $GRADLE_VERSION == *"Revision"* ]]; then
    echo "Deploying the RSP SW Toolkit - Gateway..."
else
    echo "gradle did not install properly, exiting."
    exit 1
fi
gradle clean deploy

JAVA_HOME="$(type -p java)"
if [[ $JAVA_HOME == *"java"* ]]; then
    echo
else
    echo "java did not install properly, exiting."
    exit 1
fi
RUN_DIR="$DEPLOY_DIR/rsp-sw-toolkit-gw"

if [ ! -d "$RUN_DIR/cache" ]; then
    echo "Creating cache directory..."
    mkdir "$RUN_DIR/cache"
    echo "Generating certificates..."
    cd "$RUN_DIR/cache" && ../gen_keys.sh
fi
echo
if [ ! -f "$RUN_DIR/cache/keystore.p12" ]; then
    echo "Certificate creation failed, exiting."
    exit 1
fi

if [ ! -d "$RUN_DIR/sensor-sw-repo" ]; then
    echo "Creating sensor-sw-repo directory..."
    mkdir "$RUN_DIR/sensor-sw-repo"
fi
echo "Purge old sensor software repository..."
rm -rf "$RUN_DIR/sensor-sw-repo/*"

cd "$RUN_DIR/sensor-sw-repo"
echo "Downloading the sensor software repository..."
wget https://github.com/intel/rsp-sw-toolkit-installer/raw/master/sensor-sw-repo/latest.txt && \
wget https://github.com/intel/rsp-sw-toolkit-installer/raw/master/sensor-sw-repo/$(cat latest.txt) && \
tar -xvzf $(cat latest.txt) --strip=1 && \
rm $(cat latest.txt) && \
rm latest.txt

echo "Configuring NTP Server to serve time with no Internet ..."
NTP_FILE="/etc/ntp.conf"
TMP_FILE="/tmp/ntp.conf"
NTP_STRING1="server 127.127.1.0 prefer"
NTP_STRING2="fudge 127.127.22.1"
END_OF_FILE=$(tail -n 3 "$NTP_FILE")
if [[ $END_OF_FILE == *"$NTP_STRING1"* ]]; then
  echo "Already configured!"
else
  echo "Updating $NTP_FILE"
  cp "$NTP_FILE" "$TMP_FILE"
  echo >> "$TMP_FILE"
  echo "# If you want to serve time locally with no Internet," >> "$TMP_FILE"
  echo "# uncomment the next two lines" >> "$TMP_FILE"
  echo "$NTP_STRING1" >> "$TMP_FILE"
  echo "$NTP_STRING2" >> "$TMP_FILE"
  echo >> "$TMP_FILE"
  sudo cp "$TMP_FILE" "$NTP_FILE"
  sudo /etc/init.d/ntp restart
fi

echo
cd "$PROJECTS_DIR/rsp-sw-toolkit-installer/native"
if [ ! -f "$PROJECTS_DIR/rsp-sw-toolkit-installer/native/open-web-admin.sh" ]; then
    echo "WARNING: The script open-web-admin.sh was not found."
else
    "$PROJECTS_DIR/rsp-sw-toolkit-installer/native/open-web-admin.sh" &
fi
echo "Running the RSP SW Toolkit - Gateway..."
cd "$RUN_DIR"
"$RUN_DIR/run.sh"
