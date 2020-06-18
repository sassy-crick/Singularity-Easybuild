# Singularity-Easybuild
Description:
-----------
Collection of Singularity build files and scripts to create them for popular Linux Distributions

The buildfiles folder contains the successful Singularity build recipes, tested with version 3.5.3, wheras the scripts folder contains the scripts to create the Singularity definition files which are based on EasyBuild.

Requirements:
------------
You will need to have a Linux environment and Singularity installed in it. 
If you don't have Linux, please use Vagrant to set up a virtual Linux environment.

As the software inside the containers are build using Easybuild, you will need to know the names of the Easybuild Configuration files, e.g. GCC-9.3.0.eb.
The latest version of EasyBuild will be automatically installed. 

Thus, it is probably best to install the easybuild-easyconfig files like this:

$ git clone https://github.com/easybuilders/easybuild-easyconfigs.git

and search the easybuild/easyconfigs folder for the name of the EasyBuild Configuration files you want to use. You only need the name, not the content of the files.

Usage:
-----
Using the scripts is simple. Copy them in your ~/bin folder for example and then execute::

$ container-build-debian10-envmodules.sh GCC-9.3.0.eb

You can supply a second script as well, which could be one you have created. This script will be 
read into the Singularity Build file. 

So in our example we would get a file called Singularity.GCC-9.3.0-envmod-debian10

You can build the container like this::

$ sudo singularity build GCC-9.3.0-envmod-debian10.sif Singularity.GCC-9.3.0-envmod-debian10

Equally, if you want to install software on top of the existing container manually, simply do:

$ sudo singularity build --sandbox GCC-9.3.0-envmod-debian10.sif Singularity.GCC-9.3.0-envmod-debian10

See the example below for a complete build of R-4.0.0 in two steps: We first build the toolchain container (foss-2020a) and inside the container we build R-4.0.0. This approach allows us to create our own complete environment for building complete pipelines as well. 

Example build:
-------------
This would be the complete sequence to build a container with the FOSS-2020a tool chain from EasyBuild, 
unpack the container and build for example R-4.0.0 inside the container. Of course you could to that 
all in one go as well. We are using the CentOS7 OS in this example:

We first create the Singularity Definition File. As we don't need to add a separate EasyBuild configuration
file we say 'n' here:
$ container-build-centos7-envmodules-python2.sh foss-2020a.eb
Do we need a second Easybuild recipe (y/N)?: n

$ ls
Singularity.foss-2020a-envmod-centos7

We now build the Singularity container. Note that the command 'singularity' needs to be in the 
PATH of root:
$ sudo singularity build foss-2020a-envmod-centos7.sif Singularity.foss-2020a-envmod-centos7

$ ls
Singularity.foss-2020a-envmod-centos7 foss-2020a-envmod-centos7.sif 

Now that we got a container, we can unpack it so we can add software to it. 
First we unpack:
$ sudo singularity build --sandbox foss-2020a-envmod-centos7 foss-2020a-envmod-centos7.sif

$ ls
Singularity.foss-2020a-envmod-centos7 foss-2020a-envmod-centos7.sif foss-2020a-envmod-centos7

Now we enter the container. The '-w' flag means we can write to the pseudo-chroot environment: 
$ sudo singularity shell -w foss-2020a-envmod-centos7

We become the easybuild user and install the software. We first fetch all the source files. This 
is sometimes a problem due to flakey internet connections. We then, in a second step, build the 
software. This step can take some time but is done fully automatic. Once build, we exit the 
container again:
# su -l easybuild
[easybuild]$ eb --fetch R-4.0.0-foss-2020a.eb
[easybuild]$ eb  R-4.0.0-foss-2020a.eb
[easybuild]$ exit
# exit

Finally, we build the Singularity container:
$ sudo singularity build  R-4.0.0-foss-2020a-envmod-centos7.sif foss-2020a-envmod-centos7

$ ls
Singularity.foss-2020a-envmod-centos7 foss-2020a-envmod-centos7.sif foss-2020a-envmod-centos7 R-4.0.0-foss-2020a-envmod-centos7.sif 

Now you can run R-4.0.0 on a different system like this:
$ singularity exec R-4.0.0-foss-2020a-envmod-centos7.sif R
R>

For more details about what you can do with Singularity please refer to their home page.  


Acknowledgement:
---------------
This work would not be possible without EasyBuild and I am greatful to the project and the community for their help.

Links:
-----
Singularity: https://sylabs.io/guides/3.5/admin-guide/installation.html
Vagrant: https://www.vagrantup.com/intro/getting-started
Easybuild: https://easybuild.readthedocs.io/en/latest

Updated: 18.6.2020

