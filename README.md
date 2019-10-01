# Installer

This repository contains installation scripts that provide the "Easy Button" for installing the Intel® RSP Controller application on an edge computer in order to control Intel® RSP Sensors.  There are several directories corresponding to the  different methods of deploying.


## Getting Started on Linux (recommended)

To get started on Linux please visit our [Getting Started Guide](https://software.intel.com/en-us/getting-started-with-intel-rfid-sensor-platform-on-linux)

### Getting Started on Windows

To run the Intel® RSP Controller application in a Windows® 10 environment, first install dependencies as described in Section 2.2 of the [Intel® RSP Controller application Software Installation & User Guide](https://github.com/intel/rsp-sw-toolkit-gw/blob/master/docs/Intel-RSP-Controller-App_Installation_User_Guide.pdf) and then use the build-win10.sh script to execute.


### Docker Environment

This method will download and install the Intel® RSP Controller application  source code along with all of its runtime dependencies within a Docker environment.  The script will build and deploy three separate Docker Containers.  Clone this repository if you are familiar with how to do that.  Otherwise, use the web interface to download the build.sh script.  Place it in your home directory and run it as root (i.e. sudo ./build.sh).  The build.sh script is intended to run in a Debian Linux environment ONLY.


### EdgeX Foundry Environment (Expected Q1'2020)

This method will download and install the Intel® RSP Controller application source code along with all of its runtime dependencies within an [EdgeX Foundry](https://www.edgexfoundry.org/) environment.  
