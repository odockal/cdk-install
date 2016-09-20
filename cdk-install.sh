#!/bin/bash
# Script for setting up CDK environment
# Currently tested to work on Mac, but should work on Linux also

# TODO:
# Add support for Cygwin

CDK_BASE_URL=http://cdk-builds.usersys.redhat.com/builds
PROVIDER=virtualbox
# Optionally, change the default to libvirt. Can be overriden using on CLI
#PROVIDER=libvirt

function usage {
	echo "Usage: $0 [-libvirt] latest" '[nightly|weekly]'
  echo "             Uses latest nightly (virtualbox) by default"
  echo "       $0 [-libvirt] use build_dir_url"
  echo "             Uses cdk.zip and virtualbox (or libvirt) vagrant box found at build_dir_url"
  exit 1
}

# At least one parameter is required
if [ $# -lt 1 ]
then
  usage
fi

while [ $# -gt 0 ]
do
	case $1 in
		-libvirt)
			PROVIDER=libvirt
			;;
	  latest)
	    shift
	    if [ $# == 0 ]
	    then
	      LATEST=1
	      TYPE=nightly
	    elif [ $# == 1 -a $1 == nightly ]
	    then
	      LATEST=1
	      TYPE=nightly
	    elif [ $# == 1 ] && [ $1 == weekly ]
	    then
	      LATEST=1
	      TYPE=weekly
	    else
	      usage
	    fi
	    ;;
	  use)
	    shift
	    if [ $# == 1 ]
	    then
	      LATEST=0
	      CDK_URL=${1%%/}
	    else
	      usage
	    fi
	    ;;
	  *)
	    usage
	    ;;
	esac
	shift
done

# For latest, we need to find the actual directory (based on date)
# so that we can match against what we already have on the disk
if [ $LATEST == 1 ]
then
  # We use a trick to find which actual build is the latest
  # - the sha sum will show the original folder name
  TARGET_DIR=`wget -qO- $CDK_BASE_URL/$TYPE/latest-build/cdk.zip.sha256sum|sed 's%.*/\([^/]*\)/cdk.zip%\1%'`
  CDK_URL=$CDK_BASE_URL/$TYPE/$TARGET_DIR
  #wget -r --no-parent --accept *sha256sum -nH --cut-dirs=2 $CDK_BASE_URL/$TYPE/latest-build/
else
  TARGET_DIR=${CDK_URL%%/}
  TARGET_DIR=${TARGET_DIR##*/}
fi

echo "URL to be used: $CDK_URL"
echo "Target dir: $TARGET_DIR"

# Download checksums into the target dir, overriding old files if present
wget --quiet -r --no-parent --accept *sha256sum -nH --cut-dirs=2 ${CDK_URL}/
if [ $? == 8 ] # check if wget failed on server error
then
  echo "Server returned error. Bad url?"
  exit 1
fi

# Check if cdk.zip exists locally and is correct. If not, download it.
if [ -f $TARGET_DIR/cdk.zip ] && [ `shasum -a 256 $TARGET_DIR/cdk.zip|cut -d ' ' -f 1` == `cat $TARGET_DIR/cdk.zip.sha256sum|cut -d ' ' -f 1` ]
then
  echo "cdk.zip exists and sha256 matches. Download skipped."
else
  echo "Downloading cdk.zip"
	if [ -f $TARGET_DIR/cdk.zip ]
	then
		rm $TARGET_DIR/cdk.zip
	fi
  wget -q -P $TARGET_DIR $CDK_URL/cdk.zip
fi

# Check if virtualbox/libvirt vagrant box exists locally and is correct. If not, download it.
BOX_FILE=`echo ${TARGET_DIR}/*${PROVIDER}.box.sha256sum`
BOX_FILE=${BOX_FILE##*/}
BOX_FILE=${BOX_FILE%%.sha256sum}
echo "Box file: $BOX_FILE"
if [ -f $TARGET_DIR/$BOX_FILE ] && [ `shasum -a 256 $TARGET_DIR/$BOX_FILE|cut -d ' ' -f 1` == `cat $TARGET_DIR/${BOX_FILE}.sha256sum|cut -d ' ' -f 1` ]
then
  echo "Box file exists and sha256 matches. Download skipped."
else
  echo "Downloading box"
	if [ -f $TARGET_DIR/$BOX_FILE ]
	then
		rm $TARGET_DIR/$BOX_FILE
	fi
  wget -P $TARGET_DIR $CDK_URL/$BOX_FILE
fi

# Specific settings for different platforms
# case "`uname`" in
#     CYGWIN*)
#         echo "Cygwin not yet supported"
#         usage
#         ;;
#     Darwin*)
#         ;;
#     Linux)
#         ;;
#     *)
#         ;;
# esac

####### Now we have both cdk.zip and the box locally.
####### So let's set it all up.

# Unzip cdk.zip. Override existing files
unzip -o $TARGET_DIR/cdk.zip -d $TARGET_DIR

# Destroy previous vagrant env (vagrant destroy)
if [ `vagrant global-status|grep 'components/rhel'|wc -l` == 0 ]
then
  echo "No vagrant env to be destroyed. Moving on."
elif [ `vagrant global-status|grep 'components/rhel'|wc -l` == 1 ]
then
  echo "Destroying vagrant env:"
  vagrant global-status|grep 'cdk/components'
  vagrant destroy `vagrant global-status |grep 'components/rhel'|cut -f 1 -d ' '`
else
  echo "Cannot determine vagrant env to be destroyed. Enter the ID to be destroyed:"
  vagrant global-status
  read $VAGRANT_ID
  vagrant destroy $VAGRANT_ID
fi

# Remove cdkv2 box
vagrant box remove cdkv2 --provider=$PROVIDER

# Uninstall vagrant plugins
vagrant plugin uninstall vagrant-registration vagrant-service-manager vagrant-sshfs
if vagrant plugin list|grep landrush > /dev/null
then
  vagrant plugin uninstall landrush
fi

# Install vagrant plugins
for PLUGIN in $TARGET_DIR/cdk/plugins/*.gem
do
  vagrant plugin install $PLUGIN
done

# Add vagrant box
vagrant box add cdkv2 $TARGET_DIR/$BOX_FILE --provider=$PROVIDER

echo "Done. Standard rhel-ose dir is here:"
find $TARGET_DIR -name rhel-ose
