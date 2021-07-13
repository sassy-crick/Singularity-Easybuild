#!/usr/bin/env bash
# Script to build a Singularity build file and builds the container
# all in one go. The only thing we need to know is the name of the 
# EasyBuild build file.
# We are using Python3 here instead of the no longer supported Python2

# We define some variables first:
os_python=3
change="n"

# Which version of EasyBuild are we installing?
ebversion="4.4.2"

# Where is the script located?
basedir="$(dirname $(readlink -f "$0"))"

IFS='-' read -ra ITEM <<<"${0%.sh}"
for i in "${ITEM[@]}"; do
     case ${i} in
	     ubuntu20.04 )
	     distro="ubuntu"
	     export distro_version="focal"
	     ;;
	     debian11 )
	     distro="debian"
	     export distro_version="bullseye"
	     ;;
	     debian10 )
	     distro="debian"
	     export distro_version="buster"
	     ;;
	     debian9 )
	     distro="debian"
	     export distro_version="stretch"
	     ;;
	     centos8 )
	     distro="centos"
	     export distro_version="8"
	     ;;
	     centos7 )
	     distro="centos"
	     export distro_version="7"
	     ;;
	     rocky8 )
	     distro="rocky"
	     export distro_version="8"
	     ;;

	     envmodules )
	     export mod="envmod" # This is only a shorthand, the actual package will be set further down!
	     export env_lang=" --modules-tool=EnvironmentModules --module-syntax=Tcl"
	     ;;
	     lmod )
	     export mod="lmod"
	     export env_lang=""
	     ;;
	     build )
	     oper=build
	     ;;
	     create )
	     oper=create
	     ;;
	     python2 )
	     os_python=2
	     ;;
     esac

done

# As the Singularity definition file contains information like for the author and email address,
# both of which are optional, but also the used EasyBuild version.  We check if the config file exists. 
# We make use of the .singularity directory and look for the config file
# sing-eb.conf there

if [ -f ~/.singularity/sing-eb.conf ]; then
        . ~/.singularity/sing-eb.conf
else
    echo "The Singularity definition file ~/.singularity/sing-eb.conf does not exist."
    echo "Please use this file to set the author and email address which is used in the Singularity definition file."
    echo "The file can also be used to specify the used version of EasyBuild, rather than just the latest one."
    echo "As it is not set, we define it here as version 4.4.0, the latest for this release."
    echo "The use of this is optional."
    echo "The syntax is:"
    echo 'author="YOUR NAME"'
    echo 'email="EMAIL ADDRESS"'
    echo 'eb_version="4.4.1"'
    author=''
    email=''
    export eb_version=${ebversion}
fi

# We need to double check if the version was set correctly. 

if [ -z ${eb_version} ]; then
	echo
	echo "The version of EasyBuld was not set in your ~/.singularity/sing-eb.conf file."
	echo "Thus, we set it to the latest version which is ${ebversion}"
	echo
	export eb_version=${ebversion}
fi

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
   read -p 'Do we need a second Easybuild recipe (y/N)?: ' eb_file2 
fi

# We check if we provided y/n. If explicit no in the line, we unset the variable eb_file2.
# At this stage, the variable should contain something. 
# If it happens to be empty, we catch that further down
case ${eb_file2} in
	y|yes|Y|Yes )
		read -p 'Easybuild recipe: ' eb_file2
                if [ ! -f "$eb_file2" ]; then
                echo "The file does not exist! Please place the correct build file in the current directory!"
                exit 2
                fi
		;;
	n|no|N|No )
		eb_file2=""
		echo "No second Easybuild recipe was provided" 
		;;
esac

# Some definitions
filename=Singularity."${eb_file%.eb}-${distro}-${distro_version}-${mod}"

# we are creating the singularity definition file
# This is for Debian
if [ ${distro} == "debian" ]; then 
	export distro_url="http://httpredir.debian.org/debian"
	if [ ${mod} == "envmod" ]; then export mod="environment-modules tcl"; change="y"; fi
	envsubst '${mod},${distro_url},${distro_version}' < "$basedir"/debian-template.tmpl > ${filename} 
	if [ ${change} == "y" ]; then export mod="envmod"; fi
fi

# This is for Ubuntu
if [ ${distro} == "ubuntu" ]; then 
	export distro_url="http://archive.ubuntu.com/ubuntu/"
	if [ ${mod} == "envmod" ]; then export mod="environment-modules tcl"; change="y"; fi
	envsubst '${mod},${distro_url},${distro_version}' < "$basedir"/debian-template.tmpl > ${filename} 
	sed -i "/%post/a \sed -i 's\/main\/main\ universe\/' \/etc\/apt\/sources.list" ${filename} 
	if [ ${change} == "y" ]; then export mod="envmod"; fi
fi

# This is for CentOS. Here we need to change the names of the environment modules a bit
if [ ${distro} == "centos" ]; then 
	if [ ${mod} == "envmod" ]; then export mod="environment-modules"; fi
	if [ ${mod} == "lmod" ]; then export mod="Lmod"; fi
	# There are some differences in the way CentOS7 is doing things from CentOS8
	# As we are using one template file, we do the changes here
	if [ ${distro_version} == "8" ]; then
	export distro_url="http://mirror.centos.org/centos-%{OSVERSION}/%{OSVERSION}/BaseOS/x86_64/os"
	envsubst '${mod},${distro_url},${distro_version}' < "$basedir"/centos-template.tmpl > ${filename} 
sed -i "/epel-release/a \
# This is needed for the change to CentOS8 \n\
yum install --quiet --assumeyes dnf-plugins-core \n\
dnf config-manager --set-enabled powertools " ${filename}
        fi
	if [ ${distro_version} == "7" ]; then
	export distro_url="http://mirror.centos.org/centos-%{OSVERSION}/%{OSVERSION}/os/x86_64/"
	envsubst '${mod},${distro_url},${distro_version}' < "$basedir"/centos-template.tmpl > ${filename} 
	sed -i "s/Lmod/setuptools Lmod /" ${filename}
	fi
	# we need to reset the names for the modules 
	if [ ${mod} == "environment-modules" ]; then export mod="envmod"; fi
	if [ ${mod} == "Lmod" ]; then export mod="lmod"; fi
fi

# This is for Rocky. The current version 8 is based on CentOS8, so we use most of that again
if [ ${distro} == "rocky" ]; then 
	if [ ${mod} == "envmod" ]; then export mod="environment-modules"; fi
	if [ ${mod} == "lmod" ]; then export mod="Lmod"; fi
	# As we are using Rocky, which is based on CentOS8, we need to heed this too:
	# There are some differences in the way CentOS7 is doing things from CentOS8
	# As we are using one template file, we do the changes here
	if [ ${distro_version} == "8" ]; then
	export distro_url="https://dl.rockylinux.org/pub/rocky/%{OSVERSION}/BaseOS/x86_64/os/"
#	export distro_url="http://mirror.centos.org/centos-%{OSVERSION}/%{OSVERSION}/BaseOS/x86_64/os"
	envsubst '${mod},${distro_url},${distro_version}' < "$basedir"/centos-template.tmpl > ${filename} 
sed -i "/epel-release/a \
# This is needed for the change to CentOS8 which we need in Rocky8 too\n\
yum install --quiet --assumeyes dnf-plugins-core \n\
dnf config-manager --set-enabled powertools " ${filename}
        fi
	# we need to reset the names for the modules 
	if [ ${mod} == "environment-modules" ]; then export mod="envmod"; fi
	if [ ${mod} == "Lmod" ]; then export mod="lmod"; fi
fi

# Now we can install EasyBuild
envsubst '${eb_version}' < "$basedir"/easybuild-install.tmpl >> ${filename} 

# Now we change the easybuild user for Debian or Ubuntu
if [ ${distro} == "ubuntu" ] || [ ${distro} == "debian" ]; then 
	sed -i "s/useradd/useradd -s \/bin\/bash -m/" ${filename}
fi

# If we are using fakeroot to build, the UID/GID are wrong for the user easybuild. 
# We simply add a little script to the root's bin directory to take care of that
cat >> ${filename} << 'EOF'
mkdir /root/bin
cat >> /root/bin/uid-change.sh << 'EOD'
#!/usr/bin/env bash
# script to correct the UID/GID of easybuild user
# in case fakeroot was used
chown -R easybuild:easybuild /app/
chown -R easybuild:easybuild /home/easybuild/
chown -R easybuild:easybuild /scratch/
EOD
chmod u+x /root/bin/uid-change.sh 
EOF

# For Lmod and environment modules we need to add a few things:
# This is for Lmod
if [ ${mod} == "lmod" ]; then
cat >> ${filename} << EOF 
# install Lmod RC file
cat > /etc/lmodrc.lua << EOD
scDescriptT = {
  {
    ["dir"]       = "/app/lmodcache",
    ["timestamp"] = "/app/lmodcache/timestamp",
  },
}
EOD
EOF
fi

<<<<<<< HEAD
# This is for environment modules < 4.1.x
# This is new for EasyBuild 4.4.2
# See https://github.com/easybuilders/easybuild-framework/pull/3816
=======
# This environment modules
>>>>>>> Rocky added to scripts, some minor tidy up/removal of commented out lines
if [ ${mod} == "envmod" ]; then 
cat >> ${filename} << EOF
cat >> /root/eb-envmod.path << 'EOD'
--- modules.py.orig      2020-06-09 14:06:45.709906123 +0100
+++ modules.py   2020-06-09 14:04:19.239060817 +0100
@@ -1260,6 +1260,8 @@
     """Interface to environment modules 4.0+"""
     NAME = "Environment Modules v4"
     COMMAND = os.path.join(os.getenv('MODULESHOME', 'MODULESHOME_NOT_DEFINED'), 'libexec', 'modulecmd.tcl')
+    if not os.path.exists(COMMAND):
+        COMMAND = os.getenv('MODULES_CMD', 'MODULES_CMD_NOT_DEFINED')
     REQ_VERSION = '4.0.0'
     MAX_VERSION = None
     VERSION_REGEXP = r'^Modules\s+Release\s+(?P<version>\d\S*)\s'
EOD
EOF

    case ${distro_version} in
	stretch )
	echo "patch -d /usr/local/lib/python3.5/dist-packages/easybuild/tools -p0 < /root/eb-envmod.path" >> ${filename}
	# Debian stretch is using environment module 3, so we need to do this:
	export env_lang=" --modules-tool=EnvironmentModulesC --module-syntax=Tcl"
	;;
	# This is for CentOS
	7 )
	export env_lang=" --modules-tool=EnvironmentModulesC --module-syntax=Tcl"
	;;
	8 )
<<<<<<< HEAD
	# Centos 8 seems to use Python-3.6.x
	export env_lang=" --modules-tool=EnvironmentModules --module-syntax=Tcl --allow-modules-tool-mismatch"
	;;
    esac
=======
	# Centos8 and Rocky8 seem to use Python-3.6.x
	echo "patch -d /usr/local/lib/python3.6/site-packages/easybuild/tools/  -p0 < /root/eb-envmod.path" >> ${filename}
	export env_lang=" --modules-tool=EnvironmentModules --module-syntax=Tcl --allow-modules-tool-mismatch"
	;;
    esac

>>>>>>> Rocky added to scripts, some minor tidy up/removal of commented out lines
fi

# Now we can read in the generic EasyBuild block
envsubst '${env_lang}' < "$basedir"/easybuild-template.tmpl >> ${filename}

# We check if we require another build file, as for example the checksum is incorrect
# In this case, we correct the build file and add it here
if [ ! -z ${eb_file2} ]; then
echo "cat > /home/easybuild/${eb_file2} << 'EOD'" >> ${filename}
cat ${eb_file2} >>  ${filename}
echo "EOD" >> ${filename}
# If there is another build file, we add it before the main one
cat >> ${filename} << EOF
echo "eb --fetch /home/easybuild/$eb_file2" >>  /home/easybuild/eb-install.sh 
echo "eb /home/easybuild/$eb_file2" >>  /home/easybuild/eb-install.sh 
EOF
fi

# We are adding the normal build file to the Singularity script
# We need to do it this way as we need to replace the variable
cat >> ${filename} << EOF
echo "eb --fetch ${eb_file}" >>  /home/easybuild/eb-install.sh 
echo "eb ${eb_file}" >>  /home/easybuild/eb-install.sh 
EOF

# Again, some stuff specific to lmod:
if [ ${mod} == "lmod" ]; then
cat >> ${filename} << 'EOF'
cat >> /home/easybuild/eb-install.sh << 'EOD'
mkdir -p /app/lmodcache 
$LMOD_DIR/update_lmod_system_cache_files -d /app/lmodcache -t /app/lmodcache/timestamp /app/modules/all  
EOD
EOF
fi

case ${distro} in
	ubuntu|debian )
	export src_cmd="."
	;;
	centos|rocky )
	export src_cmd="source"
	;;
esac

case ${mod} in
	lmod )
	export lmod_cache="export LMOD_SHORT_TIME=86400"
	export module_clean1="module --force purge"
	export module_clean2=""
	;;
	envmod )
	export lmod_cache=""
	export module_clean1="unset LOADEDMODULES"
        export module_clean2="unset _LMFILES_"
	;;
esac
	
# Now we can add the script which is running EasyBuild and does some of the 
# post installation
envsubst '${src_cmd},${lmod_cache},${module_clean1},${module_clean2}' < "$basedir"/easybuild-run.tmpl >> ${filename}

# This is apparently needed for Ubuntu:
if [ ${distro} == "ubuntu" ]; then
	echo "# this seems to be needed to make sure the terminal is working:" >> ${filename}
	echo "export TERM=xterm-256color" >> ${filename}
fi

# Now we finish off the Singularity definition file:
echo "# load module(s) corresponding to installed software" >> ${filename}

mod1=$(echo "$eb_file" | cut -d '-' -f 1 )
mod2=$(echo "${eb_file%.eb}" | cut -d '-' -f 2- )
module_name="$mod1/$mod2"
echo "module load $module_name " >> ${filename}
echo " " >> ${filename}
echo "%labels" >> ${filename}
if [ ! -z "${author}" ] && [ ! -z ${email} ]; then
        echo "Author ${author} <${email}>" >> ${filename}
fi
echo "EasyBuild-version ${eb_version}" >> ${filename}
echo "EasyConfig-file ${eb_file}"  >> ${filename}

if [ ${oper} == "build" ] && [ -e "$basedir"/container-build.sh ]; then
	echo "We are now building the container. Buckle up."
	"$basedir"/container-build.sh ${filename}
else
	echo "The Singularity definition file ${filename} has been created."
	echo "You can now either build a Singularity Image File, or a Sandbox on a different machine if you like."
	echo "You can use the script $basedir/container-buils.sh for that if you want to."
fi

# End

