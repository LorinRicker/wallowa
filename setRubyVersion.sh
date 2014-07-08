#!/bin/bash

# setRubyVersion
# Lorin Ricker: set up Ruby environment & commands

# Usage:
#   $ setRubyVersion  # by default, sets latest installed version
#   $ setRubyVersion 1.9.1            # ...sets specified version
#   $ setRubyVersion [-h|-?|--help]   # ...outputs usage help
#   $ setRubyVersion --howto          # ...outputs how-to help

shF="setRubyVersion"
Ident="${shF}     # (LMR version 1.3 of 10/16/2012)"

RBV=""
RB="/usr/bin/ruby"
RSLV=""
RALT="/etc/alternatives/ruby"
hlp=""

# Determine the latest version of the Ruby package,
# or use parameter $1 if given:
if [ -z "$1" ]; then
  RUBY=$( ls --format=single-column $RB* | sort -r | head -n 1 )

  if [ -f "$RUBY" ]; then

    RBV=${RUBY##$RB}  # strip path and "ruby" to get version#
    echo "%${shF}-I-version, Ruby version is ${RBV}"

    # Check and untangle Ruby-upgrade's dumb insistence on setting sym-links to
    # old and obsolete version(s), e.g., to 1.8 instead of latest 1.9.x:
    Rsymlink1=$( readlink "$RB" )
    Rsymlink2=$( readlink "$Rsymlink1" )
    RSLV=${Rsymlink2##$RB}
    if [[ "$RSLV" != "$RBV" ]]; then
      echo "%${shF}-E-VMISMATCH, Ruby version mismatch: '$RSLV' instead of '$RBV'"
      echo "  ...fixing: setting Ruby version to '$RBV'"
    fi

  else
    echo "%${shF}-E-fnf, Ruby not installed (\"$RB\")"
    RBV=""
  fi

else
  case "$1" in
    --help | -h | -? )
      hlp="1"
      cat <<-EOD1

Usage:
  $ setRubyVersion  # by default, sets latest installed version
  $ setRubyVersion 1.9.1            # ...sets specified version
  $ setRubyVersion [-h|-?|--help]   # ...outputs usage help
  $ setRubyVersion --howto          # ...outputs how-to help
EOD1
      ;;
    --howto )
      hlp="2"
      cat <<-EOD2

  How-To: Fix Ruby Installation Problems
  --------------------------------------

  Ruby installations use a double-indirection of symbolic links to
  handle version dependencies:

    /usr/bin/ruby (sym-link)
      -> /etc/alternatives/ruby (sym-link)
        -> /usr/bin/ruby<version> (executable)

  This script resets sym-links in /etc/alternatives/ and /usr/bin/
  to point at the correct version-specific Ruby component files.

  Ruby (like many programming language packages) is sensitive to
  version-specific order of installation -- it's important that
  versions are installed in ascending order (e.g., ruby1.8 must be
  installed before ruby1.9.1).  Occasionally, you might install a
  seemingly unrelated package which quietly requires an early(er)
  Ruby package version (e.g., ruby1.8 gets installed after you
  specifically installed ruby1.9.1), thus undoing the above double-
  indirect Ruby sym-links from their intended version-values.

  This problem typically manifests itself with seemingly out-of-the-
  blue Ruby script error messages; for example:

    $ ruby myscript.rb
    /home/user/bin/myscript.rb:23: undefined method 'require_relative'
    for main:Object (NoMethodError)

  So, if the listing which follows show you an earlier version of Ruby
  (ruby1.8) when you're "certain" that you'd installed ruby1.9.1, this
  shell-script will fix-up the sym-links for the latest Ruby version.

    Usage:
      $ setRubyVersion        # ...find/set latest Ruby version
    or:
      $ setRubyVersion 1.9.1  # ...to set a specific version

  Of course, if the 'ls'-listing below shows the right version, but you
  are still experiencing "weird" problems with Ruby scripts... then look
  deeper at installed package libraries, or debug your own scripts more
  thoroughly.
EOD2
       ;;
    * )
      RBV="$1"
      Rsymlink1=$( readlink "$RB" )
      Rsymlink2=$( readlink "$Rsymlink1" )
      RSLV=${Rsymlink2##$RB}
      # Alter the /etc/alternatives/rub* symbolic links to point back
      # to the requested version-links in /usr/bin/...
      if [[ "$RSLV" != "$RBV" ]]; then
        rtar="/usr/bin/ruby${RBV}"
        if [ -f "$rtar" ]; then
          echo "%${shF}-I-FIXING, updating symlinks for Ruby v${RBV}"
          # ln --symbolic --force (-sf):
          sudo ln -sf /usr/bin/ruby${RBV} /etc/alternatives/ruby
          sudo ln -sf /usr/share/man/man1/ruby${RBV}.1.gz /etc/alternatives/ruby.1.gz
          # ...and ensure that sym-link /usr/bin/ruby points through:
          sudo ln -sf /etc/alternatives/ruby /usr/bin/ruby
        else
          echo "%${shF}-E-FNF, file ${rtar} not found"
        fi
      fi
      ;;
  esac
fi

echo ""
echo "Ruby double-indirect sym-links:"
echo "-------------------------------"
ls -la /usr/bin/ruby
ls -la /etc/alternatives/ruby

# exit 0
