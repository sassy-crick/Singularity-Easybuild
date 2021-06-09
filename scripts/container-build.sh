#!/bin/bash
# Script to build a Singularity sif-container, optionally as a sandbox.
# We might want to set a temporary directory to do this but that
# is for later.
# Right now, we keep it simple
# The script needs NOT to be executed with sudo
# The only time we need sudo is to remove the chroot-directory 
# from a sandbox-build at the end of the build. 
# Thanks to Bennet Fauber and Sebastian Achilles for the inspiration
# to this script
# Version 23.2.2021

# We first check if sudo is installed at all, which we need not for the
# script but to remove the chroot-directoy later. 
command -v sudo &> /dev/null 
if [ $? != 0 ]; then
     echo "sudo is not installed, please install it first" 
     exit 1
fi

# We also need to make sure that Singularity is installed:
command -v singularity &> /dev/null 
if [ $? != 0 ]; then
      echo "Singularity is not installed, please install it first!" 
      exit 1
fi

command -v fakeroot &> /dev/null
if [ $? != 0 ]; then
      echo "fakeroot is not installed, please install it first!" 
      exit 1
fi

# Fakeroot will not work for a normal user unless a few things are set. 
# This depends on the distro, so we check that first:
os_version=$(grep -w ID /etc/*-release |cut -f 2 -d = |tr -d \")

case ${os_version} in

	debian )
	# On Debian at least, fakeroot will not work unless 
	# /proc/sys/kernel/unprivileged_userns_clone
	# is set to 1. So we better check this here first. 
	# See: https://github.com/hpcng/singularity/issues/4361
	fr_check=$(cat /proc/sys/kernel/unprivileged_userns_clone)
	if [ "$fr_check" != 1 ]; then
		echo "Please make sure that you can use fakeroot by setting this:"
		echo "cat /proc/sys/kernel/unprivileged_userns_clone"
		echo "to 1. This needs to be done at elevated privileges."
		echo "If that is not possible, you cannot use the scripts unfortunately!"
		exit 1
	fi
	;;
	centos )
	# On Centos, we can do it this way: 
	# From 7.4, kernel support is included but must be enabled with:
	# echo 10000 > /proc/sys/user/max_user_namespaces
	fr_check=$(cat /proc/sys/user/max_user_namespaces)
	if [ "$fr_check" == 0 ]; then
		echo "Please make sure that you can use fakeroot by setting this:"
		echo "cat /proc/sys/user/max_user_namespaces"
		echo "to 10000. This needs to be done at elevated privileges."
		echo "If that is not possible, you cannot use the scripts unfortunately!"
		exit 1
	fi
esac

# As we are using fakeroot, we need to make sure that the PATH is set accordingly
# This works at least for Debian
export PATH=/usr/sbin:$PATH

# Now we get the name of the Singularity definition file:
if [ ! -z "$1" ]; then
	definitionfile="$1"
  else
        read -p 'Please provide the name of the Singularity Definition file ' definitionfile
fi

# We do some manipulation of the name for the container by simply removing the
# Singularity bit at the beginning.
container="${definitionfile#Singularity.*}".sif

# We need to know if we need to build a Sandbox as well
if [ ! -z "$2" ]; then
	sandbox="$2"
else
	read -p 'Do you want to build a Sandbox as well? (y/N) ' sandbox
fi

case "${sandbox}" in
      y|Y|yes|Yes|YES )
      sandbox="yes"
      ;;
      * )
      sandbox="no"
      ;;
esac

if [ "${sandbox}" == "yes" ]; then
       # In case we want to build a sandbox, we need this 
       sandboxname=${container%.sif}
       echo "The sandbox ${sandboxname} will be build now."
       echo "Please be patient as this might take some time."
       $(command -v singularity) build --fakeroot --sandbox "${sandboxname}" "${definitionfile}" 
       if [ $? != 0 ]; then
          echo "Something went wrong" 
          exit 1
       fi
       echo "The SIF file ${container} will be build now."
       echo "Please be patient as this might take some time."
       $(command -v singularity) build --fakeroot "${container}" "${definitionfile}"
       if [ $? != 0 ]; then
          echo "Something went wrong" 
          exit 1
       fi
else
       echo "The SIF file ${container} will be build now."
       echo "Please be patient as this might take some time."
       $(command -v singularity) build --fakeroot "${container}" "${definitionfile}" 
       if [ $? != 0 ]; then
          echo "Something went wrong" 
          exit 1
       fi
fi

