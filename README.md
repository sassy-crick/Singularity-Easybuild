# Singularity-Easybuild
Description:
-----------
Collection of Singularity build files and scripts to create them for popular Linux Distributions

The buildfiles folder contains the successful Singularity build recipes wheras the scripts folder contains the scripts to create the Singularity build recipes which are based on EasyBuild.

Requirements:
------------
You will need to have a Linux environment and Singularity installed in it. 
If you don't have Linux, please use Vagrant to set up a virtual Linux environment.

As the containers are build using Easybuild, you will need to know the names of the Easybuild Configuration files, e.g. GCC-9.3.0.eb.

Thus, it is probably best to install the easybuild-easyconfig files like this:

$ git clone https://github.com/easybuilders/easybuild-easyconfigs.git

and search the easybuild/easyconfigs folder.

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

This will require some tweaking later to ensure the right modules are loaded within the container. 
Please see the Singularity website for more informations on how to do that. 


Acknowledgement:
---------------
This work would not be possible without EasyBuild and I am greatful to the project and the community for their help.

Links:
-----
Singularity: https://sylabs.io/guides/3.5/admin-guide/installation.html
Vagrant: https://www.vagrantup.com/intro/getting-started
Easybuild: https://easybuild.readthedocs.io/en/latest

