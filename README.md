# cdk-install.sh
Script for setting up CDK environment

This script is aimed at developers wishing to easily keep their cdk installation current

## Prerequisites

vagrant
wget
curl

## Usage

    $ cdk-install.sh latest
Install latest cdk nighly build.
It will create a directory, e.g. 15-Sep-2016.rc5, in your current directory in which cdk.zip and vagrant box will be downloaded.
It will reuse the files if you try to install the same version again.

    $ cdk-install.sh latest nightly
Same as above.

    $ cdk-install.sh latest weekly
Same as above, but install latest weekly instead of nightly.

    $ cdk-install.sh use http://cdk-builds.url/builds/weekly/15-Sep-2016.rc5
Use a specific build.
