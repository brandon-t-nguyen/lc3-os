# lc3-os
An operating system written for an LC3 that supports a timer device (see the lcsim repo).
This is intended to make use of the baseline LC3 assembler features: as such it will not
be written with additional features of my WIP LC3 assembler (e.g. macros).


## directory structure:

/src/kernel         ==> kernel level code

/src/lib            ==> libraries

## load order:
You can effectively load all the .objs in whatever order you want, but be sure to set the PC to 0x0200, which is the kernel entry point. *Loading kernel.obj last will set the PC at 0x0200 if you're lazy*.
