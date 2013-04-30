#!/bin/bash

# adopt.sh  -- 08/09/2012
#
# usage: anchor [options] [ dirtree | ... ]
#
# Provides a sudo-wrapper for the adoptDirTree[.rb] script which needs
# root privs. Both this bash script and its associated Ruby script must
# reside in the same directory (folder) -- for example:
#
#    ~/bin/
#       adopt(.sh)
#       adoptDirTree(.rb)

#~ path=$( readlink -f $0 )  # Expand full pathname of this script
#~ path=${path%%.sh}         # ...then strip any ".sh" extension
#~ path=${path%%adopt}       # ...and the script filename itself
#~ # echo "path = '$path'"   # to extract the script's path...

path=$( dirname $0 )

#echo "$ sudo ${path}/adoptDirTree.rb $@"
sudo ${path}/adoptDirTree.rb $@

# exit 0
