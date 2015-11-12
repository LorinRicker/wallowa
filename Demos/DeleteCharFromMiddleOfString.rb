#!/usr/bin/env ruby
# -*- encoding: utf-8 -*-

# DeleteCharFromMiddleOfString.rb
#
# Copyright © 2011-2014 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 06/04/2014
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

str = "0123456789"  # or "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
puts "str = '#{str}'"

while str.length > 0
  i = str.length / 2
  d = str[i]
  str[i] = ""
  puts "Delete char '#{d}' at pos #{i} => '#{str}'"
end  # while
