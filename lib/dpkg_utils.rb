#!/usr/bin/ruby
# -*- encoding: utf-8 -*-

# dpkg_utils.rb
#
# Copyright © 2014-2015 Lorin Ricker <Lorin@RickerNet.us>
# Version info: v0.2  12/23/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.

def package_information( package )
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
end  # package_information

def package_installed?( package )
  instatus, pkgname, pkgversion, pkgreport = package_information( package )
  return instatus
end  # package_installed?

def package_name( package )
  instatus, pkgname, pkgversion, pkgreport = package_information( package )
  return pkgname
end  # package_name

def package_version( package )
  instatus, pkgname, pkgversion, pkgreport = package_information( package )
  return pkgversion
end  # package_version

def package_report( package )
  instatus, pkgname, pkgversion, pkgreport = package_information( package )
  return pkgreport
end  # package_report
