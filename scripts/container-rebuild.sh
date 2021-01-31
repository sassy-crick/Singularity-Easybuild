#!/bin/bash
# Script to open up a Singularity sif-container as a sandbox,
# adds new lines to the already existing build script,
# builds the new software and creates a new sif-container again
# We might want to set a temporary directory to do this but that
# is for later.
# Right now, we keep it simple
# The script needs NOT to be executed with sudo
# The only time we need sudo is to remove the chroot-directory
# at the end of the build. 
# Thanks to Bennet Fauber and Sebastian Achilles for the inspiration
# to this script
# Version 31.1.2021

# We first check if sudo is installed at all, which we need not for the
# script but to remove the chroot-directoy later. 
which sudo &> /dev/null 
if [ $? != 0 ]; then
     echo "sudo is not installed, please install it first" 
     exit 1
fi

# We also need to make sure that Singularity is installed:
which singularity &> /dev/null 
if [ $? != 0 ]; then
      echo "Singularity is not installed, please install it first!" 
      exit 1
fi

# Now we get the name of the container we want to use and the 
# new EC filename, which we will add to the already existing script

# Reading of the name of the Singularity sif-container
if [ ! -z "$1" -a -e "$1" ]; then
  container="$1"
  else
  read -p 'Please provide the name of the Singularity sif-container ' container
fi

# Now we read the name of the EasyBuild configuration file. 

if [ ! -z "$2" ]; then
        eb_file="$2"
else
        read -p 'Easybuild recipe: ' eb_file
fi

# Sometimes we need to provide a EasyBuild configuration file, for example as checksums 
# have changed
if [ ! -z "$3" ]; then
   eb_file2="$3"
else
   read -p 'Do we need a second Easybuild recipe (y/N)?: ' var
        if [ "$var" == "y" ]; then
        read -p 'Easybuild recipe: ' eb_file2
                if [ ! -f "$eb_file2" ]; then
                echo "The file does not exist! Please place the correct build file in the current directory!"
                exit 2
                fi
        fi
fi

# As we got now all the required information, we can set a few variables for later
# This is for the first EasyBuild recipe:
mod1=$(echo ${eb_file} | cut -d '-' -f 1 )
mod2=$(echo ${eb_file%.eb} | cut -d '-' -f 2- )
module_name="$mod1/$mod2"

# In case we got a second one, we do the same with the second file. 

if [ ! -z "$eb_file2" ]; then
        mod3=$(echo ${eb_file2} | cut -d '-' -f 1 )
        mod4=$(echo ${eb_file2%.eb} | cut -d '-' -f 2- )
        module2_name="$mod3/$mod4"
fi

# We now unpack the container
sandboxname=${container%.sif}

# We need this for later, the name for the new container. 
distro=$( echo ${sandboxname} | awk -F "-" '{print $NF}')
module_ver=$( echo ${sandboxname} | awk -F "-" '{print $(NF-1)}')


$(which singularity) build --fakeroot --sandbox ${sandboxname} ${container} 

if [ $? != 0 ]; then
      echo "Something went wrong" 
      exit 1
fi

# We now add the additional EasyBuild configuration file name to the already
# existing script. 

echo "eb --fetch ${eb_file}" >> ${sandboxname}/home/easybuild/eb-install.sh

# In case we got a second one, we do the same with the second file.
if [ ! -z "$eb_file2" ]; then
        # check if we got a file or a name
        # IF it is a file, we need to do a bit of a dance to make that working
        if [ -f "${eb_file2}" ]; then
           echo "cat > /home/easybuild/${eb_file2} << 'EOD'" >> ${sandboxname}/home/easybuild/eb-install.sh
           cat ${eb_file2} >> ${sandboxname}/home/easybuild/eb-install.sh
           echo "EOD" >> ${sandboxname}/home/easybuild/eb-install.sh
        fi
        echo "eb --fetch ${eb_file2}" >> ${sandboxname}/home/easybuild/eb-install.sh
        echo "eb ${eb_file2}" >> ${sandboxname}/home/easybuild/eb-install.sh
fi

echo "eb ${eb_file}" >> ${sandboxname}/home/easybuild/eb-install.sh

# Now we can install that new program within the sandbox
# We stop at the first error and show what we are doing
set -ve
set -o noclobber

$(which singularity) exec -w --fakeroot ${sandboxname} su -l easybuild -c /home/easybuild/eb-install.sh

# cleanup, everything in /scratch is assumed to be temporary
$(which singularity) exec -w --fakeroot ${sandboxname} su -l easybuild -c  "rm -rf /scratch/*"

set +v

echo "module load $module_name " >> ${sandboxname}/environment

# In case we got a second one, we do the same with the second file.
if [ ! -z "$eb_file2" ]; then
        echo "module load $module2_name " >> ${sandboxname}/environment
fi

if [ ! -z "$eb_file2" ]; then
        $(which singularity) build --fakeroot ${mod3}-${mod4}-${module_ver}-${distro}.sif ${sandboxname}
        echo
        echo "The new Singularity container ${mod3}-${mod4}-${module_ver}-${distro}.sif was build"
     else
        $(which singularity) build --fakeroot ${mod1}-${mod2}-${module_ver}-${distro}.sif ${sandboxname}
        echo
        echo "The new Singularity container ${mod1}-${mod2}-${module_ver}-${distro}.sif was build"
fi

echo
echo "You can now remove the ${sandboxname} directory, which requires the sudo command"

