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

Acknowledgement:
--------------
This work would not be possible without EasyBuild and I am greatful to the project and the community for their help.

Links:
-----
[Singularity] (https://sylabs.io/guides/3.5/admin-guide/installation.html)
[Vagrant] (https://www.vagrantup.com/intro/getting-started)
[Easybuild] (https://easybuild.readthedocs.io/en/latest/)

