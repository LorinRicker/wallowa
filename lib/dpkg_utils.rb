#!/usr/bin/ruby
# -*- encoding: utf-8 -*-

# dpkg_utils.rb
#
# Copyright © 2014-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: v0.1  12/22/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

def package_installed?( package )
  pkgname = pkgversion = nil
  # dpkg-query outputs on both stdout and stderr, so redirect stderr>stdout:
  cmd = "dpkg-query --show --showformat='${Package} [${Version}] ${Status}' #{package} 2>&1"
  pkgreport = %x{ #{cmd} }
  # dpkg-query returns (as Process::Status $? or English::$CHILD_STATUS)
  #   exit status == 0 if package is installed (success),
  #               == 1 if package is *not* found/installed (fail):
  instatus = $?.success?
  pkgname, pkgversion = pkgreport.split( /[ \t]/ ) if instatus
  return [ instatus, pkgname, pkgversion, pkgreport ]
end  # package_installed?
