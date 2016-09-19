# cdk-install.sh
Script for setting up CDK environment

This script is aimed at developers wishing to easily keep their cdk installation current

## Prerequisites

* previous working installation of CDK - this is not strictly needed, but the script will not do anything outside of the things needed to change from one cdk install to another, e.g. it will not modify your /etc/groups which is apparently required on Linux
* vagrant
* wget
* curl
* unzip

## Usage

    $ cdk-install.sh latest
Install latest cdk nighly build.
It will create a directory, e.g. 15-Sep-2016.rc5, in your current directory in which cdk.zip and vagrant box will be downloaded.
It will reuse the files if you try to install the same version again.

    $ cdk-install.sh latest nightly
Same as above.

    $ cdk-install.sh -libvirt latest
Use libvirt instead of virtualbox.

    $ cdk-install.sh latest weekly
Same as above, but install latest weekly instead of nightly.

    $ cdk-install.sh use http://cdk-builds.url/builds/weekly/15-Sep-2016.rc5
Use a specific build.

## Known issues

vagrant destroy will fail if you have your Eclipse open and docker tooling connected to your cdk's docker daemon at least once.
The problem is that docker tooling locks the cert files and won't release them.
See [JBIDE-23123](https://issues.jboss.org/browse/JBIDE-23123)
