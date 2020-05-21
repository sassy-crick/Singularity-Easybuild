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
filename=Singularity."${eb_file%.eb}-Lmod-centos7"

# we are creating the singularity file

cat > "$filename" << 'EOF'
Bootstrap: yum
OSVersion: 7
MirrorURL: http://mirror.centos.org/centos-%{OSVERSION}/%{OSVERSION}/os/x86_64/
Include: yum

%post
yum --assumeyes update
yum install --quiet --assumeyes epel-release
yum install --quiet --assumeyes python3 setuptools Lmod
yum install --quiet --assumeyes python3-pip
yum install --quiet --assumeyes bzip2 gzip tar zip unzip xz
yum install --quiet --assumeyes curl wget
yum install --quiet --assumeyes patch make
yum install --quiet --assumeyes file git which
yum install --quiet --assumeyes gcc-c++
yum install --quiet --assumeyes perl-Data-Dumper
yum install --quiet --assumeyes perl-Thread-Queue
yum install --quiet --assumeyes libibverbs-dev libibverbs-devel rdma-core-devel
yum install --quiet --assumeyes openssl-devel libssl-dev libopenssl-devel openssl

# install EasyBuild using pip3
pip3 install -U pip
pip3 install wheel
pip3 install -U setuptools
pip3 install 'vsc-install<0.11.4' 'vsc-base<2.9.0'
pip3 install easybuild

# create 'easybuild' user (if missing)
id easybuild || useradd easybuild

# create /app software installation prefix + /scratch sandbox directory
if [ ! -d /app ]; then mkdir -p /app; chown easybuild:easybuild -R /app; fi
if [ ! -d /scratch ]; then mkdir -p /scratch; chown easybuild:easybuild -R /scratch; fi
if [ ! -d /home/easybuild ]; then mkdir -p /home/easybuild; chown easybuild:easybuild -R /home/easybuild;fi

# install Lmod RC file
cat > /etc/lmodrc.lua << EOD
scDescriptT = {
  {
    ["dir"]       = "/app/lmodcache",
    ["timestamp"] = "/app/lmodcache/timestamp",
  },
}
EOD

# verbose commands, exit on first error
set -ve
set -o noclobber
EOF

# We check if we require another build file, as for example the checksum is incorrect
# In this case, we correct the build file and add it here

if [ ! -z "$eb_file2" ]; then
	echo "cat > /home/easybuild/$eb_file2 << EOD" >> "$filename"
	cat "$eb_file2" >>  "$filename"
	echo "EOD" >> "$filename"
fi

cat >> "$filename" << 'EOF'
# configure EasyBuild
cat > /home/easybuild/eb-install.sh << 'EOD'
#!/bin/bash  
export EASYBUILD_PREFIX=/scratch 
export EASYBUILD_TMPDIR=/scratch/tmp 
export EASYBUILD_SOURCEPATH=/scratch/sources:/tmp/easybuild/sources 
export EASYBUILD_INSTALLPATH=/app 
export EASYBUILD_PARALLEL=4
alias eb="--robot --download-timeout=1000"
EOD
EOF

# If there is another build file, we add it before the main one
if [ ! -z "$eb_file2" ]; then
cat >> "$filename" << EOF
echo "eb /home/easybuild/$eb_file2" >>  /home/easybuild/eb-install.sh 
EOF
fi

# We are adding the normal build file to the Singularity script
# We need to do it this way as we need to replace the variable

cat >> "$filename" << EOF
echo "eb $eb_file" >>  /home/easybuild/eb-install.sh 
EOF

cat >> "$filename" << 'EOF'
cat >> /home/easybuild/eb-install.sh << 'EOD'
mkdir -p /app/lmodcache 
$LMOD_DIR/update_lmod_system_cache_files -d /app/lmodcache -t /app/lmodcache/timestamp /app/modules/all  
EOD

chmod a+x /home/easybuild/eb-install.sh

su -l easybuild -c /home/easybuild/eb-install.sh

# cleanup, everything in /scratch is assumed to be temporary
rm -rf /scratch/*

%runscript
eval "$@"

%environment
# make sure that 'module' and 'ml' commands are defined
source /etc/profile
# increase threshold time for Lmod to write cache in $HOME (which we don't want to do)
export LMOD_SHORT_TIME=86400
# purge any modules that may be loaded outside container
module --force purge
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

