#!/bin/bash
#
# Copyright (c) 2019 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause 
#

clear
echo
echo "This script will download and install the latest software"
echo "repository for Intel® RFID Sensor Platforms (H1000/H3000/H4000)."
echo "By continuing with this installation, you agree to the terms in"
echo "the End User License Agreemnt Intel-RSP-EULA-Agreement.pdf."
echo "https://github.com/intel/rsp-sw-toolkit-installer/sensor-sw-repo"
echo
echo "IMPORTANT! PLEASE READ AND AGREE TO THIS EULA BEFORE CONTINUING!"
echo 
read -p 'Press [Enter] to continue... or [Ctrl]-[C] to exit...'
echo
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
PROJECTS_DIR=$HOME/projects
DEPLOY_DIR=$HOME/deploy
RUN_DIR=$DEPLOY_DIR/rsp-sw-toolkit-gw

if [ ! -d "$RUN_DIR" ]; then
    echo "RSP Controller installation not found! exiting..."
    exit 1
fi

if [ ! -d "$RUN_DIR/sensor-sw-repo" ]; then
    echo "Creating sensor-sw-repo directory..."
    mkdir $RUN_DIR/sensor-sw-repo
fi
echo "Purge old sensor software repository..."
rm -rf $RUN_DIR/sensor-sw-repo/*

cd $RUN_DIR/sensor-sw-repo
echo "Downloading the sensor software repository..."
wget https://github.com/intel/rsp-sw-toolkit-installer/raw/master/sensor-sw-repo/latest.txt && \
wget https://github.com/intel/rsp-sw-toolkit-installer/raw/master/sensor-sw-repo/$(cat latest.txt) && \
tar -xvzf $(cat latest.txt) --strip=1 && \
rm $(cat latest.txt) && \
rm latest.txt

echo
echo "DONE"
echo "Connected sensors will periodically poll the sensor-sw-repo repository and "
echo "will automatically update if newer version is available. No further action required."
echo

