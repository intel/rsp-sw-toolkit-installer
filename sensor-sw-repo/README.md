# Sensor Software Repository

The Intel® RFID Sensor Platform (Intel® RSP) is a Linux based device whose operating system is built using the Yocto Project.  Updates to the packages in this device are released periodically in the form of an opkg repository.  When this repository is placed into the "deploy/rsp-sw-toolkit-gw/sensor-sw-repo" directory, each Intel® RSP will automatically update its software from this repository when connected to the Intel® RSP Controller application.  To comply with open source requirements, the source code for the various open source libraries used in creating the Hx000 software is also included here.  The files in this directory are...

    > Intel-RSP-EULA-Agreement.pdf
    > OpenSourceLibraries.url        (url to download the open source libraries) 
    > hx000-rrs-repo-yy.q.mm.dd.tgz  (yy.q.mm.dd is the opkg repository version)

The terms of use for this software are outlined in the Intel® RSP EULA Agreement.  **_IMPORTANT! PLEASE READ AND AGREE TO THIS EULA BEFORE DOWNLOADING THIS SOFTWARE_**


## Getting Started
If you have used the installer to install the RFID Sensor Platform (Intel® RSP) Controller application, then you just need to run [step #3](#3-execute-the-update-script)

### 1. Create Project Directory and Install GIT

``` 
mkdir -p ~/projects
cd ~/projects

sudo apt -y install git
```

### 2. Clone the RSP Installer Repository

``` 
git clone https://github.com/intel/rsp-sw-toolkit-installer.git
```

### 3. Execute the Update Script 

```
cd ~/projects/rsp-sw-toolkit-installer/sensor-sw-repo
./update.sh
```
<br/>  

> __NOTE:__  Connected sensors will periodically poll the sensor-sw-repo directory and will automatically update if newer version is available.  No further action required.
