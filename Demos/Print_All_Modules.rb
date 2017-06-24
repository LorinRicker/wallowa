#!/usr/bin/ruby1.9.1
# -*- encoding: utf-8 -*-

#  Print_All_Modules.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 04/03/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Print all modules (excluding classes):
puts Module.constants.sort.select { |x|
  eval(x.to_s).instance_of? Module
  }
