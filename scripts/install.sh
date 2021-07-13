#!/usr/bin/env bash
# This script sets the various symlinks to the singularity-definition-create.sh file.
# The options are the distributions and versions and Lmod or environment-modules
# As Python2 is depreciated, we are not using that any more.
# We also set the various paths, if required.

# Where is the script located?
BASEDIR=$(dirname "$0")

# Do we want to create definition file and build the container in one go, 
# or just create the definition file?
if [ ! -z "$1" ]; then
        oper="$1"
  else
	  read -p 'Do you want to build and create or just create the definition file? (Build/Create)? ' oper
fi
# Check we got it right:
case ${oper} in
	B|Build|build|b )
	oper="build"
	;;
	C|Create|create|c )
	oper="create"
	;;
	* )
	echo "Sorry, your input was not recognised."
	echo "I am stopping here now."
	exit 1
esac


# Which distribution do we want to use?
# Debian, Ubuntu, CentOS or Rocky
if [ ! -z "$2" ]; then
        distro="$2"
  else
	  read -p 'Which Distribution do you want to use? (Debian, Ubuntu, CentOS, Rocky)? ' distro
fi
# Check we got it right:
case ${distro} in
	Debian|debian|d )
	distro="debian"
	if [ ! -z "$3" ]; then
        	distro_version="$3"
  		else
	  	read -p 'Which version do you want to use? (Stretch, Buster, Bullseye)? ' distro_version
	fi
	case ${distro_version} in
		Stretch|stretch|9 )
			distro_version="9"
			;;
		Buster|buster|10 )
			distro_version="10"
			;;
		Bullseye|bullseye|11 )
			distro_version="11"
			;;
		*)
			echo "Sorry, your input was not recognised."
			echo "I am stopping here now."
			exit 1
	esac
	;;
	Ubuntu|ubuntu|u )
	distro="ubuntu"
	if [ ! -z "$3" ]; then
        	distro_version="$3"
  		else
	  	read -p 'Which version do you want to use? (Focal)? ' distro_version
	fi
	case ${distro_version} in
		Focal|focal|f|20.04 )
			distro_version="20.04"
			;;
		*)
			echo "Sorry, your input was not recognised."
			echo "I am stopping here now."
			exit 1
	esac
	;;
	CentOS|Centos|centos|c )
	distro="centos"
	if [ ! -z "$3" ]; then
        	distro_version="$3"
  		else
	  	read -p 'Which version do you want to use? (7, 8)? ' distro_version
	fi
	case ${distro_version} in
		7 )
			distro_version="7"
			;;
		8 )
			distro_version="8"
			;;
		*)
			echo "Sorry, your input was not recognised."
			echo "I am stopping here now."
			exit 1
	esac
	;;
	Rocky|rocky|r )
	distro="rocky"
	if [ ! -z "$3" ]; then
        	distro_version="$3"
  		else
	  	read -p 'Which version do you want to use? (8)? ' distro_version
	fi
	case ${distro_version} in
		8 )
			distro_version="8"
			;;
		*)
			echo "Sorry, your input was not recognised."
			echo "I am stopping here now."
			exit 1
	esac
	;;
	* )
	echo "Sorry, your input was not recognised."
	echo "I am stopping here now."
	exit 1
esac

# Do we want to create definition file and build the container in one go, 
# or just create the definition file?
if [ ! -z "$4" ]; then
        mod="$4"
  else
	  read -p 'Do you want to use Lmod or environment modules? (Lmod, Envmod)? ' mod
fi
# Check we got it right:
case ${mod} in
	Lmod|lmod|l )
	mod="lmod"
	;;
	Envmod|envmod|environment-modules|env|e )
	mod="envmodules"
	;;
	* )
	echo "Sorry, your input was not recognised"
	echo "I am stopping here now"
	exit 1
esac

# Do we want to install that in the user's bin dir or not?
if [ ! -z "$5" ]; then
	bin_dir="$5"
  else
	read -p 'Do you want the symbolic links to be installed in your ~/bin directory (y/n)? ' bin_dir
fi

case ${bin_dir} in
	Y|y )
	ln -s $BASEDIR/singularity-definition.sh ~/bin/container-$oper-$distro$distro_version-$mod.sh 
	;;
	N|n )
	ln -s "$BASEDIR"/singularity-definition.sh container-$oper-$distro$distro_version-$mod.sh 
	;;
esac

