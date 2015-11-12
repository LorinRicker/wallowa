#!/usr/bin/ruby1.9.1
# -*- encoding: utf-8 -*-

# QuotedOutput.rb
#
# Copyright © 2011-2012 Lorin Ricker <Lorin@RickerNet.us>
# Version 1.0, 04/03/2012
#
# This program is free software, under the terms and conditions of the
# GNU General Public License published by the Free Software Foundation.
# See the file 'gpl' distributed within this project directory tree.
#

require_relative 'pquts'

# Main -- test drivers:
if $0 == __FILE__ then
  x = "This is a test."
  pquts x
  pquts x, "X"
  x = "He said \"She is smart.\""
  pquts x
  x = "She said \"He's a geek.\""
  pquts x
end
