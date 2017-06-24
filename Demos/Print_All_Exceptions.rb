#!/usr/bin/ruby1.9.1
# -*- encoding: utf-8 -*-

# Print_All_Exceptions.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 04/03/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

# Print all exceptions:
puts Module.constants.sort.select { |x|
  c = eval(x.to_s)
  c.is_a? Class and c.ancestors.include? Exception
  }
