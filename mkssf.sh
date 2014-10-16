#!/usr/bin/env bash

# mkssf.sh
# Lorin Ricker: shell wrapper for Ruby script mkssfpath.rb

# usage:  $ ./mkssf [working_directory] [env_var_name]

# Note: In order for these scripts, bash: mkssf[.sh] and ruby: mkssfpath[.rb]
#       to affect the current process environment -- i.e., to let them define
#       "logical names" (bash variables) which are *visible in the current
#       process* -- then this corresponding alias *must* be defined to
#       *source* (.) this script file...
#       See file .../projects/login/aliases for the definition of alias "mkssf".

shF=$( basename $0 )
Ident="${shF}  # (LMR version 1.03 of 10/15/2014)"

if [ -z "$1" ]; then
  workingdir="$( pwd )"
else
  workingdir="$1"
fi

# Ruby-script mkssfpath.rb does all the heavy-lifting
host=$( echo $HOSTNAME )
scriptfile=$( mkssfpath "$workingdir" "$host" "$2" )

if [ -f $scriptfile ]; then
  ## echo "%${shF}-scriptfile, to execute then delete: ${scriptfile}"
  ## cat $scriptfile

  # Execute the shell-script created by mkssfpath...
  # Note that this too must be *source*'d (or .'d):
  source $scriptfile

  rm $scriptfile    # and clean-up...
fi

# exit 0
