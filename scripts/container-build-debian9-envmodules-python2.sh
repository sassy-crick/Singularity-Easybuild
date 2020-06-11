#!/bin/bash
# Script to build a Singularity build file and builds the container
# all in one go. The only thing we need to know is the name of the 
# EasyBuild build file.
# We are using Python3 here instead of the no longer supported Python2



# We need to know the name of the Easybuild build file:
if [ ! -z "$1" ]; then
        eb_file="$1"
else
        read -p 'Easybuild recipe: ' eb_file
fi

# Sometimes we need to provide a Easybuild build file, for example as checksums 
# have changed
if [ ! -z "$2" ]; then
   eb_file2="$2"
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
# Some definitions
filename=Singularity."${eb_file%.eb}-envmod-debian9"

# we are creating the singularity file

cat > "$filename" << 'EOF'
Bootstrap: debootstrap
OSVersion: stretch 
MirrorURL: http://httpredir.debian.org/debian

%post
apt update 
apt dist-upgrade -y 
apt install -y python python-setuptools environment-modules tcl
apt install -y python-pip
apt install -y bzip2 gzip tar zip unzip xz-utils 
apt install -y curl wget
apt install -y patch make
apt install -y file git debianutils
apt install -y gcc 
apt install -y libibverbs-dev 
apt install -y libssl-dev
apt install -y binutils libthread-queue-any-perl

# install EasyBuild using pip
pip install -U pip
pip install wheel
pip install -U setuptools
pip install 'vsc-install<0.11.4' 'vsc-base<2.9.0'
pip install easybuild

# create 'easybuild' user (if missing)
id easybuild || useradd -s /bin/bash -m easybuild

# create /app software installation prefix + /scratch sandbox directory
if [ ! -d /app ]; then mkdir -p /app; chown easybuild:easybuild -R /app; fi
if [ ! -d /scratch ]; then mkdir -p /scratch; chown easybuild:easybuild -R /scratch; fi
if [ ! -d /home/easybuild ]; then mkdir -p /home/easybuild; chown easybuild:easybuild -R /home/easybuild;fi

# verbose commands, exit on first error
set -ve
set -o noclobber
EOF

# We check if we require another build file, as for example the checksum is incorrect
# In this case, we correct the build file and add it here

if [ ! -z "$eb_file2" ]; then
	echo "cat > /home/easybuild/$eb_file2 << 'EOD'" >> "$filename"
	cat "$eb_file2" >>  "$filename"
	echo "EOD" >> "$filename"
fi

cat >> "$filename" << 'EOF'
# We set this so if we need to open the container again, we got the environment set up correctly
cat >> /home/easybuild/.bashrc << 'EOG'
export EASYBUILD_PREFIX=/scratch 
export EASYBUILD_TMPDIR=/scratch/tmp
export EASYBUILD_SOURCEPATH=/scratch/sources:/tmp/easybuild/sources
export EASYBUILD_INSTALLPATH=/app
export EASYBUILD_PARALLEL=4
export MODULEPATH=/app/modules/all
alias eb="eb --robot --modules-tool=EnvironmentModulesC --module-syntax=Tcl --download-timeout=1000"
EOG

# configure EasyBuild
cat > /home/easybuild/eb-install.sh << 'EOD'
#!/bin/bash  
shopt -s expand_aliases
export EASYBUILD_PREFIX=/scratch 
export EASYBUILD_TMPDIR=/scratch/tmp 
export EASYBUILD_SOURCEPATH=/scratch/sources:/tmp/easybuild/sources 
export EASYBUILD_INSTALLPATH=/app 
export EASYBUILD_PARALLEL=4
alias eb="eb --robot --modules-tool=EnvironmentModulesC --module-syntax=Tcl --download-timeout=1000"
EOD
EOF

# If there is another build file, we add it before the main one
if [ ! -z "$eb_file2" ]; then
cat >> "$filename" << EOF
echo "eb  --fetch /home/easybuild/$eb_file2" >>  /home/easybuild/eb-install.sh 
echo "eb /home/easybuild/$eb_file2" >>  /home/easybuild/eb-install.sh 
EOF
fi

# We are adding the normal build file to the Singularity script
# We need to do it this way as we need to replace the variable

cat >> "$filename" << EOF
echo "eb --fetch $eb_file" >>  /home/easybuild/eb-install.sh 
echo "eb $eb_file" >>  /home/easybuild/eb-install.sh 
EOF

cat >> "$filename" << 'EOF'

chmod a+x /home/easybuild/eb-install.sh

su -l easybuild -c /home/easybuild/eb-install.sh

# cleanup, everything in /scratch is assumed to be temporary
rm -rf /scratch/*

%runscript
eval "$@"

%environment
# make sure that 'module' is defined
. /etc/profile
# purge any modules that may be loaded outside container
unset LOADEDMODULES
unset _LMFILES_
# avoid picking up modules from outside of container
module unuse $MODULEPATH
# pick up modules installed in /app
module use /app/modules/all
# load module(s) corresponding to installed software
EOF

mod1=$(echo "$eb_file" | cut -d '-' -f 1 )
mod2=$(echo "${eb_file%.eb}" | cut -d '-' -f 2- )
module_name="$mod1/$mod2"
echo "module load $module_name " >> "$filename" 
echo " " >> "$filename" 
echo "%labels" >> "$filename" 
echo "Author  J. Sassmannshausen <rosalind-support@kcl.ac.uk>" >> "$filename"
echo "${eb_file%.eb}" >> "$filename" 

